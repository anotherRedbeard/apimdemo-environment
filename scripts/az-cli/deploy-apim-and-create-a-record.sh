#!/usr/bin/env bash

############################################
# Configuration Defaults (overridable)
############################################
PARAM_FILE="${PARAM_FILE:-iac/bicep/create-ws-enabled-apim-with-networking.bicepparam}"
PRIVATE_DNS_ZONE_NAME="${PRIVATE_DNS_ZONE_NAME:-azure-api.net}"
INTERNAL_GATEWAY_NAME="${INTERNAL_GATEWAY_NAME:-internal-gateway}"
API_VERSION="${API_VERSION:-2024-06-01-preview}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-20}"
POLL_TIMEOUT_SECONDS="${POLL_TIMEOUT_SECONDS:-120}"

############################################
# Helpers
############################################
warn() { echo "WARN: $*" >&2; }
fail() { echo "ERROR: $*" >&2; }

SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} -g <resourceGroup> [options]
  -g  Resource group (required)
  -s  Subscription ID
  -p  Param file (default: $PARAM_FILE)
  -z  Private DNS zone (default: $PRIVATE_DNS_ZONE_NAME)
  -G  Internal gateway name (default: $INTERNAL_GATEWAY_NAME)
  -V  API version (default: $API_VERSION)
  -i  Poll interval seconds (default: $POLL_INTERVAL_SECONDS)
  -t  Poll timeout seconds (default: $POLL_TIMEOUT_SECONDS)
  -h  Help
EOF
}

############################################
# Main
############################################
main() {
  OPTIND=1

  local RG=""
  local SUBSCRIPTION_ID=""

  # Parse flags
  while getopts ":g:s:p:z:G:V:i:t:h" opt; do
    case $opt in
      g) RG="$OPTARG" ;;
      s) SUBSCRIPTION_ID="$OPTARG" ;;
      p) PARAM_FILE="$OPTARG" ;;
      z) PRIVATE_DNS_ZONE_NAME="$OPTARG" ;;
      G) INTERNAL_GATEWAY_NAME="$OPTARG" ;;
      V) API_VERSION="$OPTARG" ;;
      i) POLL_INTERVAL_SECONDS="$OPTARG" ;;
      t) POLL_TIMEOUT_SECONDS="$OPTARG" ;;
      h) usage; return 0 ;;
      *) usage; return 0 ;;
    esac
  done

  # Validation
  if [[ -z "$RG" ]]; then fail "Resource group (-g) required"; usage; return 0; fi
  command -v az >/dev/null || { fail "az CLI not found"; return 0; }
  command -v jq >/dev/null || { fail "jq not found"; return 0; }
  if [[ ! -f "$PARAM_FILE" ]]; then
    fail "Param file not found at: $PARAM_FILE"
    return 0
  fi

  # Subscription switch (optional)
  if [[ -n "$SUBSCRIPTION_ID" ]]; then
    az account set --subscription "$SUBSCRIPTION_ID" >/dev/null 2>&1 || warn "Failed to set subscription $SUBSCRIPTION_ID"
  fi

  # Infer APIM name from param file
  local APIM_NAME
  APIM_NAME=$(grep -E "param apimName" "$PARAM_FILE" 2>/dev/null | sed -E "s/param apimName *= *'([^']+)'.*/\1/" || true)
  [[ -n "$APIM_NAME" ]] || APIM_NAME="apim"

  echo "Deploying param file: $PARAM_FILE (APIM: $APIM_NAME RG: $RG)"
  local DEPLOY_NAME="apim-$(date +%s)"
  local DEPLOY_JSON
  local DEPLOY_EXIT

 # Ensure resource group exists (idempotent)
  if ! az group show -n "$RG" >/dev/null 2>&1; then
    echo "Resource group '$RG' not found. Creating in location '$LOCATION'..."
    # Add --tags if desired, e.g.: --tags env=dev owner=platform
    if ! az group create -n "$RG" -l "$LOCATION" -o none; then
      fail "Failed to create resource group '$RG' in '$LOCATION'"
      return 0
    fi
    echo "Created resource group '$RG'."
  else
    echo "Resource group '$RG' already exists."
  fi

  # Deployment (template file)
  DEPLOY_JSON=$(az deployment group create \
    --resource-group "$RG" \
    --name "$DEPLOY_NAME" \
    --parameters "$PARAM_FILE" \
    -o json 2>&1)
  DEPLOY_EXIT=$?

  if [[ $DEPLOY_EXIT -ne 0 ]]; then
    fail "Deployment failed (exit $DEPLOY_EXIT)"
    echo "$DEPLOY_JSON"
    return 0
  fi

  # Deployment state check
  local STATE
  STATE=$(az deployment group show -g "$RG" -n "$DEPLOY_NAME" --query properties.provisioningState -o tsv 2>/dev/null || echo "")
  if [[ "$STATE" != "Succeeded" ]]; then
    warn "Deployment state: $STATE"
    az deployment operation group list -g "$RG" -n "$DEPLOY_NAME" \
      --query "[?properties.provisioningState!='Succeeded'].{res:properties.targetResource.resourceName,type:properties.targetResource.resourceType,state:properties.provisioningState,err:properties.statusMessage}" -o table || true
  else
    echo "Deployment Succeeded."
  fi

  # Subscription ID (for gateway resource ID)
  local SUB_ID
  SUB_ID=$(az account show --query id -o tsv 2>/dev/null || echo "")
  if [[ -z "$SUB_ID" ]]; then
    warn "Unable to resolve subscription ID; skipping gateway polling."
    return 0
  fi

  # Gateway endpoints
  local GATEWAY_CONFIG_NAME="gw-${INTERNAL_GATEWAY_NAME}-config"
  local GATEWAY_ID="/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.ApiManagement/gateways/$INTERNAL_GATEWAY_NAME"
  local GATEWAY_URL="https://management.azure.com${GATEWAY_ID}?api-version=${API_VERSION}"
  local GATEWAYHOST_URL="https://management.azure.com${GATEWAY_ID}/configConnections/${GATEWAY_CONFIG_NAME}?api-version=${API_VERSION}"

  local deadline=$(( $(date +%s) + POLL_TIMEOUT_SECONDS ))
  local internal_ip=""
  local runtime_host=""

  echo "Polling gateway ($INTERNAL_GATEWAY_NAME) for private IP (timeout ${POLL_TIMEOUT_SECONDS}s)..."
  while [[ $(date +%s) -lt $deadline ]]; do
    if GW_JSON=$(az rest --method get --url "$GATEWAY_URL" 2>/dev/null); then
      internal_ip=$(echo "$GW_JSON" | jq -r '.properties.frontend.inboundIPAddresses.private[0] // empty')
      if [[ -n "$internal_ip" ]]; then
        echo "Internal gateway IP: $internal_ip"
        echo "Get the Hostname"
        if GWHOST_JSON=$(az rest --method get --url "$GATEWAYHOST_URL" 2>/dev/null); then
          runtime_host=$(echo "$GWHOST_JSON" | jq -r '.properties.defaultHostname // empty')
          echo "Gateway Hostname: $runtime_host"
        fi
        break
      fi
    fi
    sleep "$POLL_INTERVAL_SECONDS"
    echo "another poll"
  done
  [[ -n "$internal_ip" ]] || warn "Gateway IP not resolved within timeout"

  echo "Ensuring Private DNS zone: $PRIVATE_DNS_ZONE_NAME"
  echo "Raw gateway hostname (runtime_host): $runtime_host"

  # Derive record label (strip the zone suffix if runtime_host is an FQDN)
  local record_label="$runtime_host"
  if [[ -n "$record_label" && "$record_label" == *".${PRIVATE_DNS_ZONE_NAME}" ]]; then
    record_label="${record_label%.${PRIVATE_DNS_ZONE_NAME}}"
  fi

  if [[ -z "$record_label" ]]; then
    warn "Derived empty record label from runtime_host '$runtime_host' - skipping DNS record creation"
    return
  fi

  echo "Using record-set name: $record_label (zone: $PRIVATE_DNS_ZONE_NAME) -> $internal_ip"

  [[ -n "$internal_ip" ]] || { warn "Skip record $record_label (empty IP)"; return; }

  # Check if record-set already has this IP
  if az network private-dns record-set a show -g "$RG" -z "$PRIVATE_DNS_ZONE_NAME" -n "$record_label" 2>/dev/null \
     --query "arecords[?ipv4Address=='$internal_ip'] | length(@)" -o tsv | grep -q "^[1-9][0-9]*$"; then
    echo "Record-set $record_label already contains $internal_ip"
  else
    # Add (this also creates record-set implicitly if it didn't exist)
    if az network private-dns record-set a add-record -g "$RG" -z "$PRIVATE_DNS_ZONE_NAME" -n "$record_label" -a "$internal_ip" -o none; then
      echo "Added $internal_ip to record-set $record_label"
    else
      warn "Failed to add $internal_ip to record-set $record_label"
    fi
  fi

  echo "Complete."
  return 0
}

############################################
# Entrypoint
############################################
main "$@"
