# Restaurante API — Semana 12

API REST para administrar mesas y reservas de un restaurante, realizada con ASP.NET Core **.NET 10**, controladores y **Entity Framework Core con SQL Server**. Swagger está disponible en desarrollo y producción.

## Tema y alcance

El restaurante necesita centralizar el registro de mesas y reservas y evitar inconsistencias de capacidad. Una **Mesa** tiene muchas **Reservas** (1:N); cada reserva tiene una clave foránea `MesaId` obligatoria. Las reservas contienen nombre del cliente, teléfono, fecha/hora, cantidad de personas y observaciones opcionales.

El alcance es el CRUD de mesas y reservas. No incluye pagos, pedidos, autenticación, disponibilidad por turnos ni detección de superposición de horarios. Las fechas representan hora local del restaurante en Lima: enviar `2030-12-10T13:00:00`, sin `Z` ni offset. El filtro `hasta` es inclusivo y compara la hora exacta; para todo un día usar `23:59:59`.

## Reglas de negocio

1. No puede repetirse el número de mesa (POST y PUT): **409**. También existe una restricción UNIQUE en SQL Server.
2. No se puede eliminar una mesa con reservas: **409**. La FK no permite eliminación en cascada.
3. Una reserva no puede superar la capacidad de la mesa: **409** (POST y PUT).
4. No se puede reducir la capacidad de una mesa por debajo de una reserva asociada: **409**.

Una mesa inexistente en una reserva responde **400**. Los ID distintos entre ruta y cuerpo responden **400**. Los recursos inexistentes responden **404**. Las Data Annotations y `[ApiController]` generan **400** automáticamente para datos inválidos.

## Requisitos locales

- SDK .NET 10 y Visual Studio Code (extensión C# Dev Kit recomendada).
- SQL Server Express, Developer o una base Azure SQL. Para ejecutar el script: `sqlcmd` o una herramienta SQL equivalente.
- No se necesita PostgreSQL ni Docker para desarrollar localmente. Dockerfile se utiliza para desplegar la API en Render.

## 1. Crear la base y ejecutar SQL

Desde la raíz del repositorio, con SQL Server Express local y autenticación de Windows:

```powershell
sqlcmd -S '.\SQLEXPRESS' -E -C -b -Q "IF DB_ID(N'RestauranteSemana12Db') IS NULL CREATE DATABASE RestauranteSemana12Db;"
sqlcmd -S '.\SQLEXPRESS' -E -C -d RestauranteSemana12Db -b -f 65001 -i sql/restaurante.sql
```

El segundo comando se ejecuta **una sola vez en una base vacía**. El script crea tablas, PK, FK, restricciones, índices y datos iniciales (4 mesas y 3 reservas), dentro de una transacción. No elimina datos existentes. En Azure SQL se crea la base desde el portal y se ejecuta el mismo script dentro de ella.

## 2. Configurar la conexión fuera del repositorio

```powershell
dotnet user-secrets set 'ConnectionStrings:RestauranteDb' '<CADENA_LOCAL_DE_SQL_SERVER>' --project RestauranteApi
dotnet tool restore
dotnet restore RestauranteApi
```

Reemplazar el marcador por la conexión de tu instancia: servidor `.\SQLEXPRESS`, base `RestauranteSemana12Db` y autenticación integrada de Windows. En este equipo ya se guardó en user-secrets. `TrustServerCertificate=True` se utiliza solo para la instancia local. En Azure SQL usar certificado verificado (`Encrypt=True;TrustServerCertificate=False`). Las cadenas de conexión no van en archivos versionados, tampoco en `.http`, capturas ni documentación de la entrega.

## 3. Database First / Scaffold

Las entidades y `RestauranteContext` se generan desde el esquema SQL, y después se ajustan sus validaciones. El comando utilizado en la primera generación es:

```powershell
dotnet ef dbcontext scaffold 'Name=ConnectionStrings:RestauranteDb' Microsoft.EntityFrameworkCore.SqlServer --project RestauranteApi --output-dir Models --context-dir Data --context RestauranteContext --namespace RestauranteApi.Models --context-namespace RestauranteApi.Data --table Mesas --table Reservas --data-annotations --no-onconfiguring
```

**No ejecutar con `--force` sobre el modelo ajustado:** sobrescribiría validaciones y cambios de navegación. Para comparar un cambio de esquema, generar primero en carpetas temporales fuera del proyecto y revisar las diferencias.

Los ajustes posteriores al Scaffold son `[Required]`, `[StringLength]`, `[Range]`, la navegación nullable `Mesa?` y `[JsonIgnore]` en `Mesa.Reservas`. La FK `MesaId` continúa siendo obligatoria. El POST de reserva puede enviar solo `mesaId` sin objeto `mesa`. Los controladores copian únicamente los campos escalares recibidos, evitando insertar grafos de entidades.

## 4. Ejecutar y abrir Swagger

```powershell
dotnet build RestauranteApi
dotnet run --project RestauranteApi --launch-profile https
```

- Swagger: https://localhost:7016/swagger
- OpenAPI: https://localhost:7016/openapi/v1.json
- Conexión y tablas: https://localhost:7016/api/estado

Si falta confiar en el certificado de desarrollo, ejecutar `dotnet dev-certs https --trust`. El perfil HTTP también está disponible en el puerto 5054. CORS permite únicamente `http://localhost:5500` por defecto; en la nube configurar `Cors__AllowedOrigin` con el origen concreto del cliente. Swagger usa el mismo origen que la API.

## Endpoints

| Método | Ruta | Resultado correcto |
|---|---|---|
| GET | `/api/mesas` | 200 |
| GET | `/api/mesas/{id}` | 200 / 404 |
| POST | `/api/mesas` | 201 + Location |
| PUT | `/api/mesas/{id}` | 204 |
| DELETE | `/api/mesas/{id}` | 204 / 409 |
| GET | `/api/mesas/{id}/reservas` | 200 / 404 |
| GET | `/api/reservas?mesaId=1&desde=2026-12-01&hasta=2026-12-31T23:59:59` | 200 |
| GET | `/api/reservas/{id}` | 200 / 404 |
| POST | `/api/reservas` | 201 + Location |
| PUT | `/api/reservas/{id}` | 204 |
| DELETE | `/api/reservas/{id}` | 204 |
| GET | `/api/estado` | 200 / 503 |

Hay 11 operaciones de negocio más el diagnóstico. Todos los controladores acceden directamente a `RestauranteContext`, con acciones async, LINQ, `ToListAsync`, `FindAsync`, `AnyAsync`, `Include`, `AsNoTracking` y `SaveChangesAsync`. No se utilizan DTOs ni repositorios. Las operaciones que cambian la capacidad o validan una reserva usan transacciones serializables para conservar la regla bajo concurrencia.

## Pruebas

Ejecutar la matriz automatizada con una URL real de la API:

```powershell
powershell -NoProfile -File pruebas/Probar-Api.ps1 -BaseUrl 'https://TU-API.onrender.com' -OutputPath 'evidencias/nube.json'
```

El script crea registros propios, prueba los endpoints y códigos 200/201/204/400/404/409, valida Location y limpia los registros que creó. Conserva solicitudes y respuestas en JSON para revisión. Reservar una mesa libre entre los números 1 y 200 para las pruebas. No ejecutar la matriz en paralelo consigo misma.

Para pruebas manuales usar Swagger o `pruebas/restaurante.http` con la extensión REST Client. Las pruebas locales ayudan al desarrollo; **la entrega exige repetirlas en la URL pública y tomar capturas**. Ver [guía de evidencias](docs/ENTREGA.md).

Se verificaron 50 solicitudes contra SQL Server Express y se comprobó Swagger en modo Production. Detalles en [verificación local](docs/VERIFICACION-LOCAL.md).

## Despliegue y entregables pendientes

Ver [guía de despliegue](docs/DESPLIEGUE.md) para Render Free + Azure SQL Database y alternativas investigadas. El repositorio contiene Dockerfile y `render.yaml` sin secretos.

La publicación requiere cuentas del estudiante, una suscripción Azure compatible con su oferta gratuita y acceso al repositorio remoto. No se considera finalizada hasta ejecutar el script en Azure SQL, publicar la API y verificar la URL pública. Los enlaces y capturas reales se completan en [ENTREGA.md](docs/ENTREGA.md).
