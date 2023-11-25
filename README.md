# apimdemo-environment
This is the repo that holds everything I need to setup a new apimdemo environment.  I keep this around in case I need to stand my demo back up in short order.

## Prerequisits

- You will need to create a new client_id and secret on an existing or new service principal.
  - Here is the command to create the new service principal
    ```# Bash script
      az ad sp create-for-rbac --name myServicePrincipalName1 --role reader --scopes /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myRG1
    ```
- Create environments for each of the apim instances under *{repository} -> Settings -> Environments* with the below secrets:

    | Secret Name | Description |
    | ------------- | ----------- |
    |APIM_INSTANCE_NAME |The name of the APIM instance to migrate from |
    |RESOURCE_GROUP_NAME|The name of the resource group the APIM instance is in|
    |AZURE_CLIENT_ID|The client id of the service principal|
    |AZURE_CLIENT_SECRET|The client secret of the service principal|
    |AZURE_SUBSCRIPTION_ID|The subscription id of the apim resource |
    |AZURE_TENANT_ID|The tenant id of the service principal|

    *Note:* The names of the environments can be dev, stage etc. If using different names, update the run-extractor.yaml and run-publisher-with-env.yaml for the environment names. This would also be a good time to setup [deployment protection rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#deployment-protection-rules) if you wish in the environment settings of GitHub.

- Grant permissions for the actions to create a PR. Set *Read and write permissions* and "Allow GitHub Actions to create and approve pull requests" under *{repository} -> Settings -> Actions -> General -> Workflow permissions*.

## Tech I'm using

- [APIOps](https://azure.github.io/apiops/)
- [Postman Collections](https://www.postman.com/collection/)
- (coming soon) bicep
