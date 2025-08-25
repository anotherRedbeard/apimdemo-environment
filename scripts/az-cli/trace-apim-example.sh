#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <subscription_id> <resource_group> <apim_name> <api_name> <apim_endpoint> <apim_subscription_key>"
    return 1
fi

# Assign arguments to variables
SUBSCRIPTION_ID=$1
RESOURCE_GROUP=$2
APIM_NAME=$3
API_NAME=$4
APIM_ENDPOINT=$5
APIM_SUBSCRIPTION_KEY=$6

# Generate access token
echo "Getting access token..."
ACCESS_TOKEN=$(az account get-access-token --resource https://management.azure.com/ --query accessToken --output tsv)

echo "Access token: $ACCESS_TOKEN"

# Verify the API exists
echo "Verifying the API exists..."
API_ID=$(az apim api show --resource-group $RESOURCE_GROUP --service-name $APIM_NAME --api-id $API_NAME --query "id" --output tsv)

if [ -z "$API_ID" ]; then
    echo "API '$API_NAME' not found in APIM instance '$APIM_NAME'."
    return 1
fi

# Use the access token to call the list debug credentials API
echo "Calling the list debug credentials API..."
DEBUG_CREDENTIALS_RESPONSE=$(az rest \
    --method post \
    --uri "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ApiManagement/service/$APIM_NAME/gateways/managed/listDebugCredentials?api-version=2024-06-01-preview" \
    --headers "{\"Authorization\": \"Bearer $ACCESS_TOKEN\"}" \
    --body '{
                "credentialsExpireAfter": "PT1H",
                "apiId": "'"$API_ID"'",
                "purposes": ["tracing"]
            }')

# Extract the token from the response
DEBUG_TOKEN=$(echo $DEBUG_CREDENTIALS_RESPONSE | jq -r .token)

if [ -z "$DEBUG_TOKEN" ]; then
    echo "Failed to retrieve debug token."
    return 1
else
    echo "Debug token:  $DEBUG_TOKEN"    
fi

# Decode the APIM endpoint URL
DECODED_APIM_ENDPOINT=$(printf '%b' "${APIM_ENDPOINT//%/\\x}")

# Use the debug token to call the actual endpoint and capture headers
echo "Calling the actual endpoint with debug token..."
RESPONSE_HEADERS=$(mktemp)
APIM_RESPONSE=$(curl -v -D $RESPONSE_HEADERS -H "Apim-Debug-Authorization: $DEBUG_TOKEN" -H "Ocp-Apim-Subscription-Key: $APIM_SUBSCRIPTION_KEY" "$DECODED_APIM_ENDPOINT")

# Print the response
echo "Response: $APIM_RESPONSE"

# Extract the trace ID from the response
TRACE_ID=$(grep -i "trace-id" $RESPONSE_HEADERS | awk '{print $2}' | tr -d '\r')

if [ -z "$TRACE_ID" ]; then
    echo "Failed to retrieve trace ID."
    return 1
fi

# Retrieve the trace logs from the management.azure.com endpoint
echo "Retrieving trace logs..."
TRACE_LOGS=$(az rest \
    --method post \
    --uri "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ApiManagement/service/$APIM_NAME/gateways/managed/listTrace?api-version=2024-06-01-preview" \
    --headers "{\"Authorization\": \"Bearer $ACCESS_TOKEN\"}" \
    --body '{
                "traceId": "'"$TRACE_ID"'"
            }')

# Print the trace logs
echo "Trace Logs: $TRACE_LOGS"