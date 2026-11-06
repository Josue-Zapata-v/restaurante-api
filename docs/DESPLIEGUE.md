# Publicación — Render + Neon

## Elección y alternativas

**Render Free para la API mediante Docker** construye la imagen oficial ASP.NET Core 10 desde el Dockerfile del repositorio. Proporciona HTTPS y una URL pública. El servicio se suspende tras 15 minutos sin tráfico y el primer acceso puede tardar alrededor de un minuto. Tiene límites mensuales de uso. [Documentación](https://render.com/docs/free).

**Neon Free para PostgreSQL** ofrece una base administrada sin tarjeta para el plan gratuito, con límites de cómputo y almacenamiento y suspensión por inactividad. Consultar los límites vigentes al crear la cuenta. Es adecuado para este proyecto académico y permite conservar la base fuera del contenedor de la API. [Planes](https://neon.com/pricing).

Alternativas investigadas: Koyeb ofrece una instancia gratuita con recursos limitados y suspensión ([documentación](https://www.koyeb.com/docs/reference/instances)); la base PostgreSQL gratuita de Render expira a los 30 días ([limitaciones](https://render.com/docs/free)). Se eligió Neon para la persistencia de los datos.

El proveedor EF Core utilizado es `Npgsql.EntityFrameworkCore.PostgreSQL` con `UseNpgsql`. El script usa sintaxis PostgreSQL, columnas identity y `timestamp without time zone` para preservar la hora local del restaurante. [Proveedor Npgsql y Scaffold](https://www.npgsql.org/efcore/).

## 1. Crear la base en Neon

1. Entrar en https://console.neon.tech y registrarse, por ejemplo con GitHub.
2. Elegir **Free** y crear un proyecto `restaurante-api`, con PostgreSQL 17 o posterior.
3. Seleccionar una región disponible cercana a la que se usará en Render.
4. En **SQL Editor**, seleccionar la base correspondiente, pegar todo `sql/restaurante.sql` y ejecutarlo una sola vez.
5. Verificar:

```sql
SELECT COUNT(*) FROM public."Mesas";    -- 4
SELECT COUNT(*) FROM public."Reservas"; -- 3
```

6. En **Connect**, obtener host, base, usuario y contraseña para la aplicación. No enviarlos al chat ni guardarlos en el repositorio.

## 2. Configurar conexión Npgsql

La variable `ConnectionStrings__RestauranteDb` espera el formato ADO.NET/Npgsql de pares clave=valor, no una URL `postgresql://...`. En la ventana Connect, elegir C#/.NET si está disponible o trasladar por separado Host, Database, Username y Password a una conexión Npgsql con TLS verificado (`SSL Mode=VerifyFull`). El host debe ser exactamente el entregado por Neon; no agregar `https://` ni rutas. Si la contraseña contiene separadores, usar NpgsqlConnectionStringBuilder o el valor correctamente entrecomillado.

Para Scaffold es preferible la conexión directa (sin `-pooler`). La API de este proyecto también puede utilizar esa conexión directa: no depende de un pooler externo. [Conexiones de Neon](https://neon.com/docs/connect/connect-from-any-app), [parámetros de Npgsql](https://www.npgsql.org/doc/connection-string-parameters.html).

## 3. Publicar la API en Render

1. Crear un **Web Service** vinculado a `Josue-Zapata-v/restaurante-api`, rama `main`.
2. Runtime **Docker**, directorio raíz del repositorio y Dockerfile `./Dockerfile`.
3. Elegir explícitamente **Free**.
4. Configurar en el panel:

| Clave | Valor |
|---|---|
| `ConnectionStrings__RestauranteDb` | Conexión Npgsql de Neon, solo en el panel de secretos |
| `Cors__AllowedOrigin` | Origen concreto, por ejemplo `http://localhost:5500` |
| `ASPNETCORE_ENVIRONMENT` | `Production` |

También puede usarse el Blueprint `render.yaml`; pide las variables secretas sin guardarlas en código. El contenedor escucha en 8080 y Render proporciona HTTPS externo. `/api/estado` es la comprobación de salud: 503 indica falta de conexión o de tablas; 200 confirma acceso al esquema.

## 4. Verificar y entregar

1. Abrir `https://TU-API.onrender.com/swagger` y `/openapi/v1.json`.
2. Verificar que `/api/estado` informa `PostgreSQL`.
3. Ejecutar:

```powershell
powershell -NoProfile -File pruebas/Probar-Api.ps1 -BaseUrl 'https://TU-API.onrender.com' -OutputPath 'evidencias/nube.json'
```

4. Repetir las operaciones en Swagger para las capturas exigidas y verificar que los cambios persisten en Neon.
5. Completar `docs/ENTREGA.md` con la URL real, evidencias y observaciones.

El primer acceso puede tardar por el arranque de la API y la reactivación de la base. La publicación y las capturas de nube solo se consideran completas después de comprobarse en la URL real.
