# Despliegue y mantenimiento — Render + Neon

## Servicios publicados

| Recurso | Configuración o enlace |
|---|---|
| Swagger público | https://restaurante-api-lohv.onrender.com/swagger |
| URL base de la API | `https://restaurante-api-lohv.onrender.com` |
| Documento OpenAPI | https://restaurante-api-lohv.onrender.com/openapi/v1.json |
| Estado de API y base | https://restaurante-api-lohv.onrender.com/api/Estado |
| Repositorio y rama | https://github.com/Josue-Zapata-v/restaurante-api — `main` |
| Hosting de la API | Render Free, servicio `restaurante-api`, runtime Docker. |
| Base de datos | Neon Free, proyecto `restaurante-api`, rama `production`, base `neondb`. |

La API y la base ya están desplegadas. Para probarlas, utilizar la **[guía del profesor](../pruebas/README.md)**. Las secciones siguientes documentan la configuración utilizada y sirven para mantenimiento o para reproducir el despliegue en un servicio nuevo.

## Elección de proveedores

**Render Free** construye la imagen ASP.NET Core 10 desde el Dockerfile del repositorio y proporciona HTTPS. El plan gratuito tiene límites de uso y suspende el servicio tras periodos de inactividad; el primer acceso puede demorar mientras se reactiva. [Documentación de Render](https://render.com/docs/free).

**Neon Free** aloja PostgreSQL como servicio administrado y mantiene la persistencia fuera del contenedor de la API. El plan gratuito tiene límites de cómputo y almacenamiento. [Planes de Neon](https://neon.com/pricing).

Alternativas investigadas: Koyeb dispone de una instancia gratuita con recursos limitados ([documentación](https://www.koyeb.com/docs/reference/instances)); la base PostgreSQL gratuita de Render tiene una duración limitada ([restricciones](https://render.com/docs/free)). Para este proyecto se eligió Render para la API y Neon para la base.

El acceso a los datos utiliza `Npgsql.EntityFrameworkCore.PostgreSQL` y `UseNpgsql`. El script está adaptado a PostgreSQL: columnas identity, varchar, claves foráneas sin cascada y timestamp sin zona horaria. [Proveedor Npgsql](https://www.npgsql.org/efcore/).

## Base de datos de Neon

La creación del proyecto se realizó desde [Neon Console](https://console.neon.tech), utilizando solo PostgreSQL. En el SQL Editor de la base `neondb` se ejecutó [sql/restaurante.sql](../sql/restaurante.sql) y se comprobaron **4 mesas y 3 reservas**.

Para consultar los conteos actuales se puede ejecutar:

```sql
SELECT 'Mesas' AS tabla, COUNT(*) AS cantidad FROM public."Mesas"
UNION ALL
SELECT 'Reservas', COUNT(*) FROM public."Reservas";
```

Los conteos iniciales pueden variar mientras se realizan pruebas. **No volver a ejecutar el script de creación sobre esta base**: las tablas ya existen. Para reproducir el esquema en otra base vacía, ejecutar el archivo completo una sola vez y comprobar que finaliza con COMMIT.

## Configuración de Render

| Campo | Valor utilizado |
|---|---|
| Repositorio | `Josue-Zapata-v/restaurante-api` |
| Branch | `main` |
| Language / runtime | `Docker` |
| Root Directory | Vacío, para utilizar la raíz del repositorio. |
| Dockerfile Path | `./Dockerfile` |
| Instance Type | `Free` |
| Puerto del contenedor | `8080` |
| Health Check Path | `/api/Estado` |

El repositorio también contiene [render.yaml](../render.yaml) para configurar un servicio mediante Blueprint. Para actualizar el servicio existente se utiliza la rama `main`; si no se inicia un despliegue automático tras el push, seleccionar **Manual Deploy → Deploy latest commit** en Render. Esperar a que aparezca **Live** antes de verificar la nueva versión.

### Variables de entorno

| Clave | Valor o finalidad |
|---|---|
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `ConnectionStrings__RestauranteDb` | Conexión Npgsql de la base Neon; su valor es secreto y solo se guarda en el panel de Render. |
| `Cors__AllowedOrigin` | `http://localhost:5500`, origen concreto autorizado para un cliente de desarrollo. No es la dirección pública de la API. |

El valor de CORS documenta la configuración actual. No es necesario cambiarlo para ejecutar Swagger, que se aloja en el mismo origen HTTPS que la API. No se utiliza `AllowAnyOrigin`.

La conexión utiliza pares clave=valor en formato ADO.NET/Npgsql. Una URL `postgresql://...` no se pega directamente como valor de esta variable. Host, Database, Username y Password deben corresponder a la misma rama y al mismo rol de Neon. Se utiliza conexión directa, sin `-pooler`, y los parámetros **`SSL Mode=VerifyFull;GSS Encryption Mode=Disable`**.

Las credenciales se consultan en **Neon → Connect** y se introducen únicamente en Render. Si la contraseña contiene separadores, se debe utilizar `NpgsqlConnectionStringBuilder` o entrecomillar correctamente el valor. No guardar la cadena real en Markdown, código, capturas o Git. [Parámetros de Npgsql](https://www.npgsql.org/doc/connection-string-parameters.html).

Después de modificar una variable, utilizar **Save and deploy** o **Save, rebuild, and deploy**. **Save only** no aplica la nueva configuración al proceso que ya está ejecutándose. [Variables y secretos de Render](https://render.com/docs/configure-environment-variables).

### HTTPS detrás del proxy

Render recibe HTTPS y reenvía tráfico HTTP al contenedor. El documento OpenAPI declara un servidor relativo `/`, por lo que Swagger conserva el origen y el protocolo del navegador. La aplicación utiliza **`RENDER_EXTERNAL_URL`**, suministrada automáticamente por Render, para generar cabeceras Location con el origen HTTPS público. No es necesario crear esa variable manualmente. [Variables predeterminadas de Render](https://render.com/docs/environment-variables).

## Verificación pública

1. Abrir [estado de la API](https://restaurante-api-lohv.onrender.com/api/Estado). Debe responder 200 con `estado: Disponible` y `baseDeDatos: PostgreSQL`.
2. Abrir [Swagger](https://restaurante-api-lohv.onrender.com/swagger) y ejecutar GET `/api/Mesas`. Request URL debe comenzar con `https://` y la respuesta debe ser 200.
3. Seguir la [guía de pruebas](../pruebas/README.md) para el CRUD, filtros y errores de negocio.

La matriz automatizada también puede ejecutarse desde la raíz del repositorio:

```powershell
powershell -NoProfile -File pruebas/Probar-Api.ps1 -BaseUrl 'https://restaurante-api-lohv.onrender.com' -OutputPath 'evidencias/nube.json'
```

El script crea y elimina registros temporales. El reporte complementa las capturas de Swagger que se adjuntan al informe; no las sustituye. Las comprobaciones realizadas se documentan en [VERIFICACION.md](VERIFICACION.md).

## Errores encontrados y solución aplicada

| Mensaje o síntoma | Causa y solución |
|---|---|
| `Couldn't set ssl mode`, valor `VerifyFul` | Error de escritura en la conexión. El valor correcto es **VerifyFull**, con dos letras l al final. |
| `28P01: password authentication failed` | Contraseña o combinación de host y rol incorrecta. Copiar la contraseña real desde Connect y comprobar los datos de la misma rama. |
| `Cannot load library libgssapi_krb5.so.2` | Intento opcional de usar GSSAPI en Npgsql 10. Se desactiva con `GSS Encryption Mode=Disable`, conservando TLS con `SSL Mode=VerifyFull`. [Referencia](https://www.npgsql.org/doc/release-notes/10.0.html). |
| Swagger muestra `Failed to fetch` y Request URL usa HTTP | Se corrigió OpenAPI para usar `/` y conservar HTTPS. Tras un nuevo despliegue, recargar Swagger con **Ctrl + Shift + R**. |
| `/api/Estado` devuelve 503 | Comprobar logs, conexión y existencia de las tablas en la base seleccionada. No repetir el script de creación si las tablas ya existen. |

El mensaje `Application is shutting down` durante un reemplazo de versión no determina por sí solo el resultado: comprobar el despliegue actual y las respuestas de los endpoints públicos.
