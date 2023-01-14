# az-containers-demo
Project to demo creating, maintaining, and deploying .NET Core apps natively and containerized on Azure PaaS services such as Azure App Service, Azure Kubernetes Service, Azure Container Apps, and Azure Container Instance.

## Prepare the app for deployment to Azure cloud servivces

### Clone the repo
Use `git clone` to clone the git repo locally on your and select the main branch

```console
git clone https://github.com/loublick-ms/az-container-demo
git branch -m main
```

### Create a local database
Use the SQLite database for immediate testing of the code and any database schema changes.

Prepare the database by running the dotnet database migrations.
```console
dotnet ef database update
```
Run the app locally to test the code and database schema. 
```console
dotnet run
```

### Create an Azure Resource Group
Create a resource group in Azure to contain all of the services required to complete this demo.
```console
az group create --name rg-container-demo --location "East US"
```

### Create an Azure SQL database server
Create an Azure SQL database server to be used by the app when deployed in the cloud.
```console
az sql server create --name dbs-container-demo --resource-group rg-container-demo --location "East US" --admin-user <db admin username> --admin-password <admin password>
```

### Create the Azure SQL database
Create the SQL Server database on the SQL Server that was just create and display the connection string. Copy and save the connection string for later use in configuring the app and the cloud services.
```console
az sql db create --resource-group rg-container-demo --server dbs-container-demo --name todoDB --service-objective S0
az sql db show-connection-string --client ado.net --server dbs-container-demo --name todoDB
```

### Update the C# code to connect to the Azure SQL database
Update the database context in Startup.cs to connect to the Azure SQL database instead of the local SQLite database

`services.AddDbContext<MyDatabaseContext>(options => options.UseSqlServer(Configuration.GetConnectionString("MyDbConnection")));`

### Update the .NET Entity Framework code to access the Azure SQL database
Delete the database migrations associated with the SQLite database.
```console
rm -r Migrations
```

Recreate migrations for Azure SQL
```console
dotnet ef migrations add InitialCreate
```

Create an Azure SQL database connection string environment variable in Powershell.
```console
$env:ConnectionStrings:MyDbConnection=<database connection string>
```

Run the .NET database migrations for Azure SQL database to create the database schema.
```console
dotnet ef database update
```

Run the web app locally with the Azure SQL database.
```console
dotnet run
```

## Build a container image for the app and store it in Azure Container Registry

### Create a container image for the app.
Create a Dockerfile to build the container image.
```
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /source

# copy csproj and restore as distinct layers
COPY todoapp/*.csproj .
RUN dotnet restore --use-current-runtime  

# copy everything else and build app
COPY todoapp/. .
RUN dotnet publish -c Release -o /app --self-contained
#--use-current-runtime --self-contained false --no-restore

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "todoapp.dll"]
```






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

