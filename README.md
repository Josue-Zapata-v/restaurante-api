# Restaurante API — Semana 12

API REST de mesas y reservas con **ASP.NET Core .NET 10**, controladores, **Entity Framework Core + PostgreSQL (Npgsql)** y **Swagger** disponible también en producción.

## Tema y modelo

Centraliza el registro de mesas y reservas de un restaurante. Una Mesa tiene muchas Reservas (1:N); cada Reserva tiene una clave foránea MesaId obligatoria. No incluye pagos, pedidos, autenticación ni detección de solapamiento de horarios.

Los horarios son locales de Lima. Enviar `2030-12-10T13:00:00`, sin `Z` ni offset. La columna se almacena como `timestamp(0) without time zone`. El filtro `hasta` es inclusivo y compara la hora exacta; para un día completo usar `23:59:59`.

## Reglas de negocio

1. Número de mesa repetido en POST o PUT: **409**, también protegido por UNIQUE en la base.
2. Eliminar una mesa con reservas: **409**, con FK sin cascada.
3. Registrar o modificar una reserva que supera la capacidad: **409**.
4. Reducir la capacidad por debajo de una reserva asociada: **409**.

Una clave foránea inexistente responde **400**; los ID distintos entre ruta y cuerpo, **400**; un recurso inexistente, **404**. `[ApiController]` y `[Required]`, `[StringLength]`, `[Range]` producen **400** automáticamente para datos inválidos.

## Inicio local con PostgreSQL

Requisitos: .NET SDK 10, Visual Studio Code y Docker Desktop iniciado. Desde la raíz:

```powershell
powershell -NoProfile -File scripts/Preparar-Local.ps1
dotnet tool restore
dotnet restore RestauranteApi
dotnet run --project RestauranteApi --launch-profile http
```

El script genera una clave local aleatoria en `.env` (ignorado por Git), inicia PostgreSQL 17 en `127.0.0.1:5433`, ejecuta el SQL en el primer inicio de la base vacía y guarda la conexión en user-secrets. El volumen de Docker conserva los datos. El script se puede repetir sin reiniciar los datos. **No borrar `.env` mientras se conserva el volumen**, porque la contraseña de una base ya creada no cambia al modificar esa variable.

- Swagger: http://localhost:5054/swagger
- OpenAPI: http://localhost:5054/openapi/v1.json
- Estado y proveedor: http://localhost:5054/api/estado
- Perfil HTTPS opcional: `dotnet run --project RestauranteApi --launch-profile https`, puerto 7016.
- Detener la base sin eliminar datos: `docker compose stop postgres`.

También puede usarse una instalación PostgreSQL existente o Neon sin Docker: ejecutar `sql/restaurante.sql` dentro de una base vacía y configurar su conexión Npgsql con `dotnet user-secrets set 'ConnectionStrings:RestauranteDb' '<CONEXION_NPGSQL>' --project RestauranteApi`. No introducir credenciales en archivos versionados ni en el chat.

## SQL primero y Scaffold

`sql/restaurante.sql` crea tablas, claves, restricciones, índices y 4 mesas + 3 reservas dentro de una transacción. Se ejecuta una sola vez por base vacía; no elimina datos. Los nombres con mayúsculas requieren comillas dobles: `SELECT * FROM public."Mesas";`.

El proyecto sigue **Database First**. Para generar una copia del modelo desde PostgreSQL sin sobrescribir las validaciones del proyecto:

```powershell
dotnet ef dbcontext scaffold 'Name=ConnectionStrings:RestauranteDb' Npgsql.EntityFrameworkCore.PostgreSQL --project RestauranteApi --output-dir ../.local/scaffold/Models --context-dir ../.local/scaffold/Data --context RestauranteContext --namespace RestauranteApi.Models --context-namespace RestauranteApi.Data --table Mesas --table Reservas --data-annotations --no-onconfiguring
```

Revisar esa copia y trasladar los cambios preservando Data Annotations, `[JsonIgnore]` en Mesa.Reservas, la navegación nullable `Mesa?` y la validación de fechas. No se usa `EnsureCreated`, `Migrate`, DTOs ni repositorios. Cada controlador accede directamente al DbContext con LINQ y acciones async (`ToListAsync`, `FindAsync`, `AnyAsync`, `Include`, `AsNoTracking`, `SaveChangesAsync`). Las operaciones de capacidad y reservas usan transacciones serializables.

## Endpoints

| Método | Ruta | Éxito |
|---|---|---|
| GET | `/api/mesas` | 200 |
| GET | `/api/mesas/{id}` | 200 |
| POST | `/api/mesas` | 201 + Location |
| PUT | `/api/mesas/{id}` | 204 |
| DELETE | `/api/mesas/{id}` | 204 |
| GET | `/api/mesas/{id}/reservas` | 200 |
| GET | `/api/reservas?mesaId=1&desde=2026-12-01&hasta=2026-12-31T23:59:59` | 200 |
| GET | `/api/reservas/{id}` | 200 |
| POST | `/api/reservas` | 201 + Location |
| PUT | `/api/reservas/{id}` | 204 |
| DELETE | `/api/reservas/{id}` | 204 |
| GET | `/api/estado` | 200 / 503 |

La ruta anidada devuelve 404 si la mesa no existe y 200 con una lista vacía si existe sin reservas. Los POST aceptan Id omitido o 0. La reserva requiere solo los escalares y MesaId; no es necesario enviar el objeto Mesa.

## Pruebas

Para evaluar la API publicada desde Swagger, consultar la **[guía de pruebas para el profesor](pruebas/README.md)**. Incluye las solicitudes en orden, sus cuerpos, los códigos esperados y la limpieza de los registros creados.

```powershell
powershell -NoProfile -File pruebas/Probar-Api.ps1 -BaseUrl 'http://localhost:5054' -OutputPath 'evidencias/local.json'
```

La matriz verifica el proveedor PostgreSQL, los endpoints y códigos 200/201/204/400/404/409, Location, filtros, persistencia y CORS. Crea registros propios y los limpia al terminar. Los reportes se guardan fuera de Git. Para pruebas manuales usar Swagger o `pruebas/restaurante.http` con REST Client. No ejecutar la matriz en paralelo consigo misma.

## Publicación

Repositorio: https://github.com/Josue-Zapata-v/restaurante-api

Elección: **Render Free para la API + Neon Free para PostgreSQL**. Las dos partes deben publicarse. Ver [despliegue](docs/DESPLIEGUE.md), [entrega](docs/ENTREGA.md) y [verificación local](docs/VERIFICACION-LOCAL.md).

La conexión se guarda en `ConnectionStrings__RestauranteDb` dentro de Render, nunca en el repositorio. CORS permite solo el origen concreto configurado en `Cors__AllowedOrigin`, por defecto `http://localhost:5500`. Swagger funciona en el mismo origen de la API y no depende de CORS.

La entrega exige repetir las pruebas sobre la URL pública y capturar cada endpoint y código de respuesta. Las verificaciones locales no sustituyen ese requisito.
