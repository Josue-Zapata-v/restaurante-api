# Restaurante API — Semana 12

API REST para gestionar mesas y reservas de un restaurante, desarrollada con **ASP.NET Core .NET 10**, controladores, **Entity Framework Core**, **PostgreSQL** y **Swagger**. La API está publicada en **Render** y sus datos se almacenan en **Neon**.

## Acceso a la API publicada

| Recurso | Enlace |
|---|---|
| **Swagger: explorar y probar la API** | **https://restaurante-api-lohv.onrender.com/swagger** |
| Documento OpenAPI | https://restaurante-api-lohv.onrender.com/openapi/v1.json |
| Estado de API y base de datos | https://restaurante-api-lohv.onrender.com/api/Estado |
| Listado de mesas | https://restaurante-api-lohv.onrender.com/api/Mesas |
| Listado de reservas | https://restaurante-api-lohv.onrender.com/api/Reservas |
| Repositorio | https://github.com/Josue-Zapata-v/restaurante-api |

**Para evaluar el proyecto, abrir Swagger y seguir la [guía de pruebas para el profesor](pruebas/README.md).** No es necesario instalar .NET, Docker ni una base de datos en el equipo para utilizar la API pública. En el plan gratuito, el primer acceso puede demorar mientras se reactiva el servicio.

La URL base es `https://restaurante-api-lohv.onrender.com`. La interfaz del proyecto se encuentra en `/swagger`.

## Problema que resuelve y modelo de datos

El restaurante necesita centralizar la información de sus mesas y reservas. La API permite registrar, consultar, modificar y eliminar esos datos, verificando que las operaciones respeten la capacidad disponible y la relación entre los registros.

| Entidad | Información principal |
|---|---|
| **Mesa** | ID, número único de mesa, capacidad y ubicación. |
| **Reserva** | ID, nombre del cliente, teléfono, fecha y hora, cantidad de personas, observaciones y MesaId. |

La relación es **uno a muchos (1:N)**: una mesa puede tener varias reservas y cada reserva pertenece a una sola mesa mediante la clave foránea obligatoria `MesaId`. La propiedad de navegación `Mesa?` permite crear reservas enviando solo la clave foránea. `[JsonIgnore]` en la colección de reservas de la mesa evita ciclos al serializar JSON.

El alcance comprende la administración de mesas y reservas; no incluye pagos, pedidos, autenticación ni detección de solapamiento de horarios.

## Reglas de negocio y validaciones

| Regla | Respuesta si se incumple |
|---|---|
| No repetir el número de otra mesa al crear o modificar. | **409 Conflict** |
| No eliminar una mesa con reservas asociadas. | **409 Conflict** |
| No registrar ni modificar una reserva con más personas que la capacidad de la mesa. | **409 Conflict** |
| No reducir la capacidad de una mesa por debajo de la cantidad de personas de una reserva asociada. | **409 Conflict** |

Una clave foránea inexistente o un ID de ruta distinto del cuerpo responde **400**. Un recurso inexistente responde **404**. Las anotaciones `[Required]`, `[StringLength]` y `[Range]`, junto con `[ApiController]`, generan **400** automáticamente para datos inválidos. La base complementa estas reglas con claves foráneas y una restricción de número único de mesa.

Las fechas representan la **hora local de Lima**. Se envían como `2030-12-10T13:00:00`, sin `Z` ni offset, y se almacenan como `timestamp(0) without time zone`. El filtro `hasta` es inclusivo y compara la hora exacta; para consultar un día completo puede utilizarse `23:59:59`.

## Endpoints

Todas las rutas se ejecutan sobre `https://restaurante-api-lohv.onrender.com`.

| Método | Ruta | Resultado correcto |
|---|---|---|
| GET | `/api/Mesas` | 200 |
| GET | `/api/Mesas/{id}` | 200 |
| POST | `/api/Mesas` | 201 + Location |
| PUT | `/api/Mesas/{id}` | 204 |
| DELETE | `/api/Mesas/{id}` | 204 |
| GET | `/api/Mesas/{id}/reservas` | 200 |
| GET | `/api/Reservas` | 200 |
| GET | `/api/Reservas/{id}` | 200 |
| POST | `/api/Reservas` | 201 + Location |
| PUT | `/api/Reservas/{id}` | 204 |
| DELETE | `/api/Reservas/{id}` | 204 |
| GET | `/api/Estado` | 200 si hay acceso a la base; 503 si no está disponible. |

El listado de reservas admite los filtros opcionales `mesaId`, `desde` y `hasta`. Por ejemplo:

```http
GET https://restaurante-api-lohv.onrender.com/api/Reservas?mesaId=1&desde=2026-12-01T00:00:00&hasta=2026-12-31T23:59:59
```

La ruta anidada devuelve **404** si la mesa no existe y **200** con `[]` si existe sin reservas. Los POST aceptan el ID omitido o en 0; los PUT requieren que el ID del cuerpo coincida con el de la ruta. Un **204** no incluye cuerpo de respuesta.

## Pruebas sobre la API en la nube

- **[Guía manual para el profesor](pruebas/README.md):** contiene las 22 pruebas en orden, sus cuerpos, códigos esperados y eliminación de los registros temporales.
- **[Archivo de solicitudes HTTP](pruebas/restaurante.http):** preparado con la URL pública para la extensión REST Client de VS Code.
- **[Script de pruebas](pruebas/Probar-Api.ps1):** verifica el proveedor PostgreSQL, CRUD, filtros, Location, persistencia, validaciones y CORS.

Desde la raíz del repositorio, para ejecutar la matriz automatizada sobre la API publicada:

```powershell
powershell -NoProfile -File pruebas/Probar-Api.ps1 -BaseUrl 'https://restaurante-api-lohv.onrender.com' -OutputPath 'evidencias/nube.json'
```

El script crea registros propios y los elimina al terminar. No ejecutarlo simultáneamente con otra instancia del mismo script. Para las pruebas manuales, elegir un número de mesa libre y utilizar los ID reales devueltos por los POST, como indica la guía.

Las capturas para la evaluación se realizan sobre **Swagger público**, mostrando método, URL HTTPS, datos enviados, código real y respuesta. Para los POST debe mostrarse también **Location**. Los reportes y capturas pueden guardarse en `evidencias/`, excluida de Git, y adjuntarse al informe.

## Publicación y configuración

| Componente | Servicio utilizado |
|---|---|
| API ASP.NET Core .NET 10 | **Render Free**, mediante el Dockerfile de este repositorio. |
| Base PostgreSQL | **Neon Free**, proyecto `restaurante-api`, rama `production`, base `neondb`. |
| Código fuente | **GitHub**, rama `main` del repositorio enlazado arriba. |

El script [sql/restaurante.sql](sql/restaurante.sql) ya se ejecutó en Neon y se verificaron **4 mesas y 3 reservas iniciales**. Los conteos pueden cambiar durante las pruebas. No es necesario volver a ejecutar el script sobre la base publicada para usar la API.

La conexión se configura únicamente en `ConnectionStrings__RestauranteDb` dentro de Render. Se utiliza el proveedor `Npgsql.EntityFrameworkCore.PostgreSQL` y `UseNpgsql`. Swagger conserva HTTPS usando el mismo origen del navegador; los enlaces Location utilizan la URL pública que Render suministra mediante `RENDER_EXTERNAL_URL`.

Consultar [despliegue y mantenimiento](docs/DESPLIEGUE.md) para la configuración real y las soluciones a los errores encontrados.

## Implementación y desarrollo

El modelo es **Database First**: el script crea el esquema y Scaffold genera las entidades y el DbContext. Después se incorporan las validaciones y ajustes de navegación. Los controladores utilizan directamente el contexto, sin DTOs ni repositorios, con LINQ y operaciones async: `ToListAsync`, `FindAsync`, `AnyAsync`, `Include`, `AsNoTracking` y `SaveChangesAsync`. Las operaciones de capacidad y reservas usan transacciones serializables.

Las instrucciones para ejecutar el proyecto en un equipo y regenerar el modelo se encuentran en **[desarrollo local y Scaffold](docs/DESARROLLO.md)**. Ese entorno es opcional y no se necesita para evaluar la API publicada.

## Documentación

| Documento | Contenido |
|---|---|
| [Pruebas para el profesor](pruebas/README.md) | Solicitudes y resultados esperados en Swagger público. |
| [Despliegue y mantenimiento](docs/DESPLIEGUE.md) | Render, Neon, variables de entorno y resolución de errores. |
| [Entrega](docs/ENTREGA.md) | Tema, enlaces, matriz de evidencias, observaciones y conclusiones. |
| [Verificación del proyecto](docs/VERIFICACION.md) | Comprobaciones de la API pública e historial de pruebas locales. |
| [Desarrollo local y Scaffold](docs/DESARROLLO.md) | Preparación opcional del entorno de desarrollo. |
