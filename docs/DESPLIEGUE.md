# Publicación en la nube

## Elección de proveedores

**Render Free para la API, con Docker**, permite usar una imagen oficial ASP.NET Core 10 sin depender de un runtime nativo del proveedor. Incluye HTTPS y una URL pública. El servicio gratuito se suspende tras 15 minutos sin tráfico y puede tardar alrededor de un minuto en reactivarse; hay límites mensuales de uso. [Render Free](https://render.com/docs/free), [servicios web](https://render.com/docs/web-services).

**Azure SQL Database con su oferta gratuita** mantiene el proveedor de SQL Server utilizado en clase, el script T-SQL y `UseSqlServer`. La oferta documentada incluye 100 000 vCore-segundos y 32 GB de datos por base al mes, condicionada a una suscripción compatible. Seleccionar la opción de pausa al alcanzar el límite gratuito, no la continuidad con cargos. [Oferta oficial](https://learn.microsoft.com/en-us/azure/azure-sql/database/free-offer?view=azuresql).

Alternativas investigadas: Koyeb ofrece una instancia gratuita de 512 MB con suspensión por inactividad ([documentación](https://www.koyeb.com/docs/reference/instances)). Neon ofrece PostgreSQL gratuito ([planes](https://neon.com/pricing)), pero requeriría cambiar de proveedor y adaptar el script. Para este proyecto se eligió mantener **SQL Server**. No se requiere instalar PostgreSQL ni usar Neon.

Consultar las condiciones vigentes al crear los recursos; una prueba de crédito temporal no equivale a la oferta gratuita seleccionada. No se crea ningún recurso de pago como parte de este repositorio.

## 1. Repositorio GitHub

Crear un repositorio y subir la carpeta raíz, que incluye `Dockerfile`, `render.yaml`, `RestauranteApi` y `sql`. Revisar primero que no existan secretos versionados. Los archivos `appsettings.json` solo contienen configuración pública; la conexión se obtiene de secretos de usuario o variables de entorno.

## 2. Azure SQL

1. Crear una base usando explícitamente la oferta gratuita compatible con tu suscripción y la opción **pausar hasta el siguiente mes al alcanzar el límite**.
2. Crear o elegir un servidor lógico SQL y sus credenciales, sin copiarlas al repositorio ni al chat.
3. Habilitar acceso público con reglas de firewall restringidas. Agregar temporalmente la IP del equipo para ejecutar el script.
4. Abrir la base correcta con una herramienta SQL y ejecutar `sql/restaurante.sql` una vez.
5. Verificar `SELECT COUNT(*) FROM dbo.Mesas` (4) y `SELECT COUNT(*) FROM dbo.Reservas` (3).
6. Obtener la conexión ADO.NET y mantener `Encrypt=True;TrustServerCertificate=False`.

Para conectar la API desde Render se necesita autenticación SQL u otro mecanismo compatible configurado expresamente. La autenticación integrada de Windows de la conexión local **no sirve para el contenedor en Render**.

## 3. Render

1. Crear un Web Service desde el repositorio (o un Blueprint usando `render.yaml`).
2. Seleccionar runtime **Docker**, directorio raíz del repositorio y plan **Free**.
3. Configurar variables de entorno en el panel:

| Clave | Valor |
|---|---|
| `ConnectionStrings__RestauranteDb` | Cadena ADO.NET de Azure SQL con su contraseña, solo en Render |
| `Cors__AllowedOrigin` | Origen concreto, por ejemplo `http://localhost:5500` para un cliente local |
| `ASPNETCORE_ENVIRONMENT` | `Production` |

4. El Dockerfile escucha HTTP en el puerto 8080 y Render proporciona HTTPS externo. La redirección HTTPS local solo se habilita en Development para evitar problemas detrás del proxy.
5. En la configuración de Render consultar los rangos de **Outbound IP addresses** del servicio. Autorizar esos rangos en el firewall de Azure SQL. Evitar abrir la base a todo internet. Retirar la regla temporal del equipo si ya no se necesita.
6. Usar `/api/estado` como comprobación de salud. Devuelve 503 si la base no está accesible o falta ejecutar el script.
7. Comprobar `https://TU-API.onrender.com/swagger` y `/openapi/v1.json`.

## 4. Validar la entrega

Ejecutar `pruebas/Probar-Api.ps1` contra la URL HTTPS pública y realizar las capturas manuales. Las pruebas locales no reemplazan este paso. Comprobar que los cambios persisten en Azure SQL. Guardar los enlaces reales, los proveedores y las limitaciones observadas en `docs/ENTREGA.md`.

## Observaciones técnicas

- Se usa SQL Server tanto en desarrollo como en la nube; no se realiza cambio de proveedor de EF Core.
- El modelo es Database First: no se invoca `EnsureCreated` ni `Migrate` al arrancar.
- OpenAPI y SwaggerUI se habilitan también en Production. [Microsoft: OpenAPI en ASP.NET Core 10](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/aspnetcore-openapi?view=aspnetcore-10.0).
- El primer acceso puede demorarse por la suspensión de la API o la pausa de la base gratuita. Esperar la reactivación antes de repetir la matriz.
- Ningún enlace de despliegue ni captura de nube se da por completado antes de verificarse en el servicio real.
