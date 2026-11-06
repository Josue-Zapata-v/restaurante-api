# Entrega — Web API REST Semana 12

## Explicación del tema

La API centraliza la administración de mesas y reservas de un restaurante. Permite registrar y consultar la información, modificarla y eliminarla cuando las reglas de negocio lo permiten. Las entidades son Mesa y Reserva, relacionadas 1:N mediante Reserva.MesaId. Una mesa puede tener muchas reservas; cada reserva corresponde a una mesa.

Reglas con respuesta 409: número de mesa único; prohibición de eliminar mesas con reservas; cantidad de personas no superior a la capacidad; prohibición de reducir la capacidad por debajo de una reserva asociada.

## Enlaces reales (completar después de publicar)

- Repositorio: https://github.com/Josue-Zapata-v/restaurante-api
- Swagger público: **PENDIENTE**.
- Hosting elegido: **Render Free**.
- Base de datos elegida: **Neon Free (PostgreSQL)**.
- Ejecución del script en Neon: **PENDIENTE**.
- Pruebas y capturas contra la API pública: **PENDIENTES**.

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

Cuando una fila agrupa varias solicitudes, tomar una captura por solicitud. Guardar las imágenes en `evidencias/` con nombres descriptivos. El archivo JSON del script de pruebas complementa las capturas, no las sustituye.

## Observaciones

- La API implementa controladores async con acceso directo al DbContext y consultas LINQ.
- El modelo se genera desde una base PostgreSQL creada por script, luego se incorporan validaciones y ajustes de serialización.
- Las claves foráneas y restricciones únicas en la base complementan las comprobaciones de los controladores.
- Las fechas corresponden a la hora local de Lima. No se implementa detección de solapamiento de reservas.
- Anotar aquí las limitaciones observadas de los servicios gratuitos durante las pruebas públicas: **PENDIENTE**.

## Conclusiones técnicas

La relación 1:N permite administrar las reservas sin duplicar los datos de las mesas. Las Data Annotations y los códigos HTTP expresan los errores de validación y los conflictos de negocio de forma consistente. Se utiliza PostgreSQL mediante el proveedor Npgsql de EF Core y el método UseNpgsql. El script usa columnas identity, texto varchar, claves foráneas sin cascada y timestamp sin zona horaria. La elección del proveedor permite usar Neon Free para la persistencia en la nube. Swagger permite explorar el contrato y realizar pruebas sin construir un frontend.

La conclusión sobre el funcionamiento en internet se completará cuando se verifiquen la API publicada y la persistencia en Neon; no debe afirmarse como realizada antes de esa comprobación.
