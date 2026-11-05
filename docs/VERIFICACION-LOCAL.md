# Verificación local realizada

Esta comprobación sirve para desarrollo. **No acredita el despliegue ni sustituye las capturas exigidas en la nube.**

- Fecha local: 4 de noviembre de 2026 (America/Lima).
- Motor verificado: SQL Server 2025 Express, instancia local SQLEXPRESS.
- Base creada para esta actividad: `RestauranteSemana12Db`.
- Script ejecutado: `sql/restaurante.sql`, con 4 mesas y 3 reservas iniciales.
- Modelo generado realmente con `dotnet ef dbcontext scaffold`, proveedor `Microsoft.EntityFrameworkCore.SqlServer`, `--data-annotations` y `--no-onconfiguring`.
- Entidades ajustadas después de la generación: validaciones, `Mesa?` y `[JsonIgnore]`.
- Build: correcto, 0 errores y 0 advertencias.
- Publicación Release con `dotnet publish`: correcta.
- Matriz HTTP en desarrollo: **50 solicitudes verificadas**, incluidas 200, 201, 204, 400, 404 y 409. Reporte local: `evidencias/local.json` (no se versiona; puede regenerarse con el script de pruebas).
- Verificación adicional con la compilación publicada ejecutada en **Production**: `/api/estado`, `/swagger/index.html` y `/openapi/v1.json` devolvieron 200.
- CORS: el origen configurado `http://localhost:5500` fue autorizado; un origen ajeno no recibió cabecera de autorización.
- Después de las pruebas, la base conserva las 4 mesas y 3 reservas originales. Los registros temporales se eliminaron.

Se retiró del proyecto el proveedor Npgsql utilizado en el borrador inicial. No se instaló un servidor PostgreSQL. La herramienta `dotnet-ef` se declara localmente en `.config/dotnet-tools.json`, sin exigir una instalación global. Los paquetes descargados a la caché compartida de NuGet no son dependencias activas del proyecto.

Pendiente: repositorio remoto, base Azure SQL, publicación de Render, ejecución del script en la nube y pruebas/capturas sobre la URL pública.
