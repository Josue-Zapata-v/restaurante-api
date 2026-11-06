# Desarrollo local y Scaffold

Estas instrucciones son opcionales para desarrollar o modificar el código. **Para evaluar la aplicación publicada, usar [Swagger en Render](https://restaurante-api-lohv.onrender.com/swagger) y la [guía de pruebas](../pruebas/README.md)**; no es necesario levantar este entorno.

## Preparar el entorno

Requisitos: SDK .NET 10, Visual Studio Code y Docker Desktop iniciado. Desde la raíz del repositorio:

```powershell
powershell -NoProfile -File scripts/Preparar-Local.ps1
dotnet tool restore
dotnet restore RestauranteApi
dotnet run --project RestauranteApi --launch-profile http
```

El script genera una clave local aleatoria en `.env`, ignorado por Git, inicia PostgreSQL 17 en `127.0.0.1:5433` y guarda la conexión en user-secrets. El script SQL se ejecuta automáticamente durante el primer inicio de la base vacía. El volumen de Docker conserva los datos y el script de preparación puede repetirse sin reiniciarlos.

No borrar `.env` mientras se conserva el volumen: cambiar la variable de contraseña no cambia la contraseña de una base ya creada. Para detener PostgreSQL conservando los datos, ejecutar `docker compose stop postgres`.

Las siguientes direcciones son **exclusivamente del entorno local**:

| Recurso local | URL |
|---|---|
| Swagger | http://localhost:5054/swagger |
| OpenAPI | http://localhost:5054/openapi/v1.json |
| Estado | http://localhost:5054/api/Estado |

El perfil HTTPS opcional se inicia con `dotnet run --project RestauranteApi --launch-profile https` y utiliza el puerto 7016.

También puede utilizarse una instalación PostgreSQL existente o una base de desarrollo de Neon. Para una base nueva y vacía, ejecutar `sql/restaurante.sql` y configurar la conexión con user-secrets. Obtener el valor real de forma privada; no incluirlo en archivos versionados:

```powershell
dotnet user-secrets set 'ConnectionStrings:RestauranteDb' '<CONEXION_PRIVADA_DE_DESARROLLO>' --project RestauranteApi
```

El marcador anterior representa un secreto que cada desarrollador debe configurar. No reemplaza ni modifica las variables del servicio publicado en Render. Para pruebas de desarrollo, utilizar preferentemente una base independiente de la de evaluación.

## Database First y Scaffold

[sql/restaurante.sql](../sql/restaurante.sql) crea tablas, claves, restricciones, índices y datos iniciales dentro de una transacción. Los nombres con mayúsculas requieren comillas dobles, por ejemplo `SELECT * FROM public."Mesas";`. No se utiliza `EnsureCreated` ni `Migrate` al arrancar la API.

Para generar una copia del modelo desde la conexión de desarrollo configurada sin sobrescribir las validaciones del proyecto:

```powershell
dotnet ef dbcontext scaffold 'Name=ConnectionStrings:RestauranteDb' Npgsql.EntityFrameworkCore.PostgreSQL --project RestauranteApi --output-dir ../.local/scaffold/Models --context-dir ../.local/scaffold/Data --context RestauranteContext --namespace RestauranteApi.Models --context-namespace RestauranteApi.Data --table Mesas --table Reservas --data-annotations --no-onconfiguring
```

Revisar los archivos generados y trasladar los cambios preservando `[Required]`, `[StringLength]`, `[Range]`, `[JsonIgnore]` en `Mesa.Reservas`, la navegación nullable `Mesa?` y la validación de fechas. No sobrescribir automáticamente el modelo ajustado mediante `--force`.

## Pruebas locales

Con la API local iniciada:

```powershell
powershell -NoProfile -File pruebas/Probar-Api.ps1 -BaseUrl 'http://localhost:5054' -OutputPath 'evidencias/local.json'
```

La matriz verifica los endpoints y códigos HTTP y limpia sus propios registros temporales. Las pruebas locales sirven para desarrollo; la evaluación del despliegue utiliza [la URL real](https://restaurante-api-lohv.onrender.com/swagger). Los resultados históricos se encuentran en [verificación del proyecto](VERIFICACION.md).
