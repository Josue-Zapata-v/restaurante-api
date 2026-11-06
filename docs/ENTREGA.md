# Entrega — Web API REST Semana 12

## Explicación del tema

La API centraliza la administración de mesas y reservas de un restaurante. Permite registrar y consultar la información, modificarla y eliminarla cuando las reglas de negocio lo permiten. Las entidades son Mesa y Reserva, relacionadas 1:N mediante Reserva.MesaId. Una mesa puede tener muchas reservas; cada reserva corresponde a una mesa.

Reglas con respuesta 409: número de mesa único; prohibición de eliminar mesas con reservas; cantidad de personas no superior a la capacidad; prohibición de reducir la capacidad por debajo de una reserva asociada.

## Enlaces y proveedores de la publicación

- Repositorio: https://github.com/Josue-Zapata-v/restaurante-api
- Swagger público: https://restaurante-api-lohv.onrender.com/swagger
- Documento OpenAPI: https://restaurante-api-lohv.onrender.com/openapi/v1.json
- Estado de API y base de datos: https://restaurante-api-lohv.onrender.com/api/Estado
- Hosting: **Render Free**, API ASP.NET Core .NET 10 desplegada mediante Docker.
- Base de datos: **Neon Free (PostgreSQL)**, proyecto `restaurante-api`, rama `production` y base `neondb`.
- Script ejecutado en Neon: [restaurante.sql](../sql/restaurante.sql), con las tablas y los datos iniciales confirmados (4 mesas y 3 reservas).
- Guía para evaluar los endpoints: [pruebas en Swagger](../pruebas/README.md).
- Registro de comprobaciones realizadas: [verificación del proyecto](VERIFICACION.md).

La API y la base de datos están alojadas en la nube. Las credenciales se configuran como variables de entorno en Render y no se incluyen en el repositorio.

## Matriz de capturas

Cada imagen debe mostrar método, URL HTTPS pública, cuerpo enviado si corresponde y código de respuesta. Para 201 mostrar también Location; para 204 el cuerpo vacío es correcto. No mostrar cadenas de conexión, contraseñas o paneles de secretos.

| Evidencia | Operación / escenario | Código |
|---|---|---|
| 01 | GET mesas | 200 |
| 02 | GET mesa por ID | 200 |
| 03 | POST mesa | 201 |
| 04 | PUT mesa | 204 |
| 05 | DELETE mesa sin reservas | 204 |
| 06 | GET reservas | 200 |
| 07 | GET reservas con mesaId, desde y hasta | 200 |
| 08 | GET reserva por ID | 200 |
| 09 | POST reserva (solo FK, sin objeto Mesa) | 201 |
| 10 | PUT reserva | 204 |
| 11 | DELETE reserva | 204 |
| 12 | GET mesas/{id}/reservas | 200 |
| 13 | Campo obligatorio ausente / vacío | 400 |
| 14 | Rango o longitud inválidos | 400 |
| 15 | ID de ruta distinto al cuerpo | 400 |
| 16 | Clave foránea inexistente | 400 |
| 17 | GET de recurso inexistente | 404 |
| 18 | PUT y DELETE de recursos inexistentes | 404 |
| 19 | POST y PUT de número de mesa duplicado | 409 |
| 20 | DELETE de mesa con reservas | 409 |
| 21 | POST y PUT de reserva que supera capacidad | 409 |
| 22 | PUT de mesa con reducción incompatible de capacidad | 409 |
| 23 | GET ruta anidada de mesa inexistente | 404 |
| 24 | GET estado de la API y base de nube | 200 |

Cuando una fila agrupa varias solicitudes, tomar una captura por solicitud. Las imágenes se adjuntan al informe de evaluación. Pueden organizarse localmente en `evidencias/`, carpeta excluida de Git. El archivo JSON del script de pruebas complementa las capturas, no las sustituye. La guía de pruebas incluye los cuerpos y el orden de ejecución para reproducir los casos.

## Observaciones

1. Observamos que la relación uno a muchos entre mesas y reservas permite organizar la información del restaurante sin duplicar los datos de cada mesa.
2. Notamos que las validaciones y reglas de negocio evitan registrar datos incorrectos, repetir números de mesa y crear reservas que superen la capacidad disponible.

## Conclusiones

1. Aprendimos a desarrollar una API REST con ASP.NET Core y Entity Framework Core, utilizando consultas LINQ y operaciones asíncronas para administrar mesas y reservas.
2. Comprendimos la importancia de utilizar códigos de respuesta HTTP adecuados y Swagger para documentar y comprobar el funcionamiento de los endpoints.
3. Logramos publicar la API en Render y la base de datos PostgreSQL en Neon, manteniendo la conexión fuera del repositorio mediante variables de entorno.

## Notas técnicas

Se utiliza PostgreSQL mediante el proveedor `Npgsql.EntityFrameworkCore.PostgreSQL` y el método `UseNpgsql`. El script usa columnas identity, texto varchar, claves foráneas sin cascada y timestamp sin zona horaria. El modelo se genera con Scaffold desde la base creada por script y después se incorporan las Data Annotations y los ajustes de serialización. Las fechas se interpretan en hora local de Lima. El alcance no incluye detección de solapamiento de reservas.
