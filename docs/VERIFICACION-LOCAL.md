# Verificación local con PostgreSQL

Esta comprobación sirve para desarrollo. **No acredita la publicación ni sustituye las capturas exigidas en la nube.**

El procedimiento es ejecutar `scripts/Preparar-Local.ps1`, generar una copia del modelo con Scaffold, compilar, iniciar la API y ejecutar `pruebas/Probar-Api.ps1`. El reporte se escribe en `evidencias/local.json`, ignorado por Git.

## Resultados del 5 de noviembre de 2026

- PostgreSQL 17 ejecutándose en Docker, con volumen persistente y puerto enlazado únicamente a localhost.
- Script PostgreSQL ejecutado correctamente en una base vacía: 4 mesas y 3 reservas iniciales.
- Scaffold ejecutado realmente con `Npgsql.EntityFrameworkCore.PostgreSQL`; contexto generado aplicado y validaciones conservadas.
- Compilación: correcta, **0 errores y 0 advertencias**.
- Publicación Release con `dotnet publish`: correcta.
- Matriz HTTP: **50 solicitudes correctas**, con códigos 200, 201, 204, 400, 404 y 409. Incluye comprobación explícita del proveedor PostgreSQL, persistencia de los PUT, Location y reglas de negocio.
- El reporte local anterior se reemplazó por el generado con PostgreSQL. Los registros temporales de pruebas se eliminaron.
- La compilación publicada se inició en modo **Production**: estado, Swagger y OpenAPI devolvieron 200; el origen CORS configurado fue autorizado.
- Se repitió el script de preparación local: conservó las 4 mesas y 3 reservas y no reinició los datos.

Pendiente externo: crear el proyecto Neon, ejecutar allí el script y publicar la API en Render para obtener las evidencias públicas.
