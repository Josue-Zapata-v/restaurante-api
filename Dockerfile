FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY RestauranteApi/RestauranteApi.csproj RestauranteApi/
RUN dotnet restore RestauranteApi/RestauranteApi.csproj
COPY RestauranteApi/ RestauranteApi/
RUN dotnet publish RestauranteApi/RestauranteApi.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
USER $APP_UID
ENTRYPOINT ["dotnet", "RestauranteApi.dll"]
