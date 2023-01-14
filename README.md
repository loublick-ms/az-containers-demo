# az-containers-demo
Project to demo creating, maintaining, and deploying .NET Core apps natively and containerized on Azure PaaS services such as Azure App Service, Azure Kubernetes Service, Azure Container Apps, and Azure Container Instance.

## Clone the repo
Use `git clone` to clone the git repo locally on your and select the main branch
git clone https://github.com/loublick-ms/az-container-demo
git branch -m main

## Intialize and test the local database
Run the local SQLite database migrations and run the app locally
dotnet ef database update
dotnet run
http://localhost:5000

# Create the Azure resource group
az group create --name rg-container-demo --location "East US"

# Create the Azure SQL Database logical server
az sql server create --name dbs-container-demo --resource-group rg-container-demo --location "East US" --admin-user <db admin username> --admin-password <admin password>

# Create the Azure SQL database and show the connection string
az sql db create --resource-group rg-container-demo --server dbs-container-demo --name todoDB --service-objective S0
az sql db show-connection-string --client ado.net --server dbs-container-demo --name todoDB


# Update the application code to connect to the Azure SQL Database instead of the local SQLite database
services.AddDbContext<MyDatabaseContext>(options => options.UseSqlServer(Configuration.GetConnectionString("MyDbConnection")));

# Delete the database migrations associated with the SQLite database
rm -r Migrations

# Recreate migrations with UseSqlServer (see previous snippet)
dotnet ef migrations add InitialCreate

# Set connection string to production database in Powershell
$env:ConnectionStrings:MyDbConnection=<database connection string>


# Run database migrations for Azure SQL Database
dotnet ef database update

# Run the web app locally with the Azure SQL Database
dotnet run

# Prepare code changes for commit and perform the commit
git add .
git commit -m "Connect to SQLDB in Azure"

# Configure the deployment user
az webapp deployment user set --user-name <app service admin username> --password <app service password>

# Create the App Service Plan
az appservice plan create --name asp-appsrv-sql-demo --resource-group rg-appsrv-sql-demo --sku FREE

# Create the web app
az webapp create --resource-group rg-appsrv-sql-demo --plan asp-appsrv-sql-demo --name wa-appsrv-sql-demo --deployment-local-git

# Get local IP of web app
az webapp config hostname get-external-ip --webapp-name wa-appsrv-sql-demo --resource-group rg-appsrv-sql-demo

# Disable access for all IP address ranges
az sql server firewall-rule create --resource-group rg-appsrv-sql-demo --server dbs-appsrv-sql-demo --name AllowAzureIps --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Enable access for this client IP address range
az sql server firewall-rule create --name AllowLocalClient --server dbs-appsrv-sql-demo --resource-group rg-appsrv-sql-demo --start-ip-address=<webapp-ip> --end-ip-address=<webapp-ip>


LOCAL GIT
https://<app service admin username>@wa-appsrv-sql-demo.scm.azurewebsites.net/wa-appsrv-sql-demo.git


# Configure the web app with the connection string for the Azure SQL Database 
az webapp config connection-string set --resource-group rg-appsrv-sql-demo --name wa-appsrv-sql-demo --settings MyDbConnection='<database connection string>' --connection-string-type SQLAzure

# Configure the Azure deployment to use the main branch of the remote git repo
az webapp config appsettings set --name wa-appsrv-sql-demo --resource-group rg-appsrv-sql-demo --settings DEPLOYMENT_BRANCH='main'

# Add an Azure remote deployment git repo
git remote add azure https://lxbasadmin@wa-appsrv-sql-demo.scm.azurewebsites.net/wa-appsrv-sql-demo.git

# Push to the Azure remote git repo to deploy the web app
git push azure main

# Run the web app deployed to Azure
https://wa-appsrv-sql-demo.azurewebsites.net

---------------------------------------------------------------------------------------------------------------------------------------------------------------

# Configure the deployment user
az webapp deployment user set --user-name <app service admin username> --password <app service admin password>

# Create unique web app name
$webappname="mywebapp" + $(Get-Random)

# Create the web app in Azure
az webapp create --resource-group rg-appsrv-sql-demo --plan asp-appsrv-sql-demo --name $webappname --deployment-local-git

LOCAL GIT URL
https://lxbasadmin@mywebapp1320142488.scm.azurewebsites.net/mywebapp1320142488.git


# Set the deployment branch to main in the appsettings configuration
az webapp config appsettings set --name $webappname --resource-group rg-appsrv-sql-demo --settings DEPLOYMENT_BRANCH=main

# Display the web app URL for use later
echo Web app URL: http://$webappname.azurewebsites.net

# Add the remote git URL to the local repo
# git remote add azure https://lxbasadmin@mywebapp1320142488.scm.azurewebsites.net/mywebapp1320142488.git

# Push the local main branch
git push azure main 

# Run the web app deployed to Azure
https://mywebapp1320142488.azurewebsites.net

