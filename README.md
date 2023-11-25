# apimdemo-environment
This is the repo that holds everything I need to setup a new apimdemo environment.  I keep this around in case I need to stand my demo back up in short order.

## Prerequisits

- You will need to create a new client_id and secret on an existing or new service principal.
  - Here is the command to create the new service principal
    ```# Bash script
      az ad sp create-for-rbac --name myServicePrincipalName1 --role reader --scopes /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myRG1
    ```

## Tech I'm using

- (APIOps)[https://azure.github.io/apiops/]
- (Postman Collections)[https://www.postman.com/collection/]
- (coming soon) bicep
