#
# Dockerfile
#
# https://github.com/loublick-ms/az-containers-demo
#
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