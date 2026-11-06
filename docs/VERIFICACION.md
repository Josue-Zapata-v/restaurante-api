# Verificación del proyecto

## Verificación de la API pública

La API está publicada en Render y consulta una base PostgreSQL alojada en Neon. El 6 de noviembre de 2026 se comprobaron mediante solicitudes HTTPS estos recursos:

| Recurso | URL pública | Resultado |
|---|---|---|
| Swagger | https://restaurante-api-lohv.onrender.com/swagger/index.html | **200** |
| OpenAPI | https://restaurante-api-lohv.onrender.com/openapi/v1.json | **200** |
| Estado y base de datos | https://restaurante-api-lohv.onrender.com/api/Estado | **200** |
| Mesas | https://restaurante-api-lohv.onrender.com/api/Mesas | **200** |
| Reservas con su mesa | https://restaurante-api-lohv.onrender.com/api/Reservas | **200** |

La respuesta del estado confirma la conexión y el acceso a las tablas:

```json
{
  "estado": "Disponible",
  "baseDeDatos": "PostgreSQL"
}
```

El script se ejecutó en Neon y se confirmaron inicialmente **4 mesas y 3 reservas**. Los conteos pueden variar durante las pruebas de creación y eliminación.

Swagger utiliza el origen de la página mediante el servidor relativo `/` del documento OpenAPI. Se corrigió la generación de URLs detrás del proxy de Render y se verificó una solicitud desde Swagger con HTTPS y respuesta 200. Las cabeceras Location se generan con el origen HTTPS público proporcionado por Render.

La **[guía de pruebas](../pruebas/README.md)** documenta el CRUD y los seis códigos HTTP requeridos. Esta verificación de disponibilidad no afirma que se hayan archivado capturas de todos los casos; las capturas de evaluación se adjuntan al informe.

## Verificación local de desarrollo

El procedimiento es ejecutar `scripts/Preparar-Local.ps1`, generar una copia del modelo con Scaffold, compilar, iniciar la API y ejecutar `pruebas/Probar-Api.ps1`. El reporte se escribe en `evidencias/local.json`, ignorado por Git.

### Resultados del 5 de noviembre de 2026

- PostgreSQL 17 ejecutándose en Docker, con volumen persistente y puerto enlazado únicamente a localhost.
- Script PostgreSQL ejecutado correctamente en una base vacía: 4 mesas y 3 reservas iniciales.
- Scaffold ejecutado realmente con `Npgsql.EntityFrameworkCore.PostgreSQL`; contexto generado aplicado y validaciones conservadas.
- Compilación: correcta, **0 errores y 0 advertencias**.
- Publicación Release con `dotnet publish`: correcta.
- Matriz HTTP: **50 solicitudes correctas**, con códigos 200, 201, 204, 400, 404 y 409. Incluye comprobación explícita del proveedor PostgreSQL, persistencia de los PUT, Location y reglas de negocio.
- El reporte local anterior se reemplazó por el generado con PostgreSQL. Los registros temporales de pruebas se eliminaron.
- La compilación publicada se inició en modo **Production**: estado, Swagger y OpenAPI devolvieron 200; el origen CORS configurado fue autorizado.
- Se repitió el script de preparación local: conservó las 4 mesas y 3 reservas y no reinició los datos.

Las comprobaciones locales registradas arriba corresponden al entorno de desarrollo. Para evaluar la entrega se utiliza la URL pública y la guía de pruebas enlazada, sin necesidad de levantar el proyecto localmente.
