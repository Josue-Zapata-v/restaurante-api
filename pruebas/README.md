# Guía de pruebas de la API publicada

Esta guía permite comprobar desde Swagger el CRUD de mesas y reservas, los filtros, la relación 1:N y las respuestas **200, 201, 204, 400, 404 y 409**. No requiere instalar herramientas ni ejecutar el proyecto localmente.

- **Swagger:** https://restaurante-api-lohv.onrender.com/swagger
- **URL base:** https://restaurante-api-lohv.onrender.com

## Preparación y uso de Swagger

1. Abrir Swagger mediante el enlace HTTPS anterior. El primer acceso puede tardar por la reactivación del servicio gratuito.
2. Desplegar el endpoint, pulsar **Try it out**, completar los parámetros o reemplazar el cuerpo de ejemplo y pulsar **Execute**.
3. Revisar **Server response**, que contiene el código real y el cuerpo recibido. La sección **Responses / Example Value** describe el contrato y no es el resultado de la prueba.
4. Ejecutar las pruebas en el orden indicado: algunas necesitan los registros creados en pasos anteriores.

### Identificadores y datos de prueba

| Referencia | Significado |
|---|---|
| **M** | ID real de la mesa creada en la prueba 1. No es el número de mesa 180. |
| **R** | ID real de la reserva creada en la prueba 10. |
| **180** | Número elegido para la mesa temporal; debe estar libre antes de empezar. |
| **2147483647** | ID utilizado para probar recursos inexistentes; se presupone que no está asignado. |

Los cuerpos que contienen **M** o **R** son **plantillas**: reemplazar esas letras por los ID reales, como números **sin comillas**, antes de enviarlos. Por ejemplo, si el POST de mesa devuelve `"id": 8`, reemplazar `"mesaId": M` por `"mesaId": 8` y escribir `8` en el parámetro de ruta correspondiente. No enviar las letras literalmente ni asumir que los ID se generan consecutivamente.

Antes de comenzar, ejecutar:

| Solicitud | Resultado esperado |
|---|---|
| GET `/api/Mesas` | **200**, listado de mesas. Permite verificar que el número 180 está libre. |
| GET `/api/Mesas/1` | **200**, mesa de ejemplo con número 1 y ubicación Salón principal, si se conserva el conjunto inicial. |

Si el número 180 ya está ocupado, elegir otro número libre entre 1 y 200 y sustituir **180** por ese número en toda la guía. No eliminar una mesa existente para liberar el número. La prueba 8 presupone que existe otra mesa con número **1**; si no existe, usar el número de otra mesa existente distinta de M.

Las fechas de los ejemplos corresponden a la hora local de Lima y se envían **sin `Z` ni offset**. Un **204** correcto no tiene cuerpo de respuesta. Las pruebas negativas deben conservar los registros sin cambios. Para registrar evidencia, mostrar método, URL pública, cuerpo enviado cuando corresponda, código real y respuesta; para un 201 incluir también **Location**.

## 1. Crear una mesa — 201

**POST `/api/Mesas`**

```json
{
  "numero": 180,
  "capacidad": 4,
  "ubicacion": "Terraza de pruebas"
}
```

**Esperado:** `201 Created`, con el objeto creado y un ID generado. Anotar ese ID como **M**. Revisar que **Location** apunta a `https://restaurante-api-lohv.onrender.com/api/Mesas/M`, sustituyendo M por el ID real.

## 2. Número duplicado — 409

Repetir exactamente el **POST `/api/Mesas`** de la prueba 1.

**Esperado:** `409 Conflict`, porque el número de mesa ya existe. No debe crearse otra mesa.

## 3. Campo obligatorio ausente — 400

**POST `/api/Mesas`**

```json
{
  "numero": 181,
  "capacidad": 4
}
```

**Esperado:** `400 Bad Request`, con un error de validación por la ausencia de `ubicacion`.

## 4. Rango inválido — 400

**POST `/api/Mesas`**

```json
{
  "numero": 181,
  "capacidad": 0,
  "ubicacion": "Prueba"
}
```

**Esperado:** `400 Bad Request`. La capacidad debe estar entre 1 y 20.

## 5. Longitud inválida — 400

**POST `/api/Reservas`**. Reemplazar **M** en esta plantilla:

```text
{
  "nombreCliente": "Cliente de prueba",
  "telefono": "123456789012345678901",
  "fechaHora": "2030-12-10T13:00:00",
  "cantidadPersonas": 2,
  "mesaId": M
}
```

**Esperado:** `400 Bad Request`. El teléfono contiene 21 caracteres y el máximo permitido es 20. No se crea ninguna reserva.

## 6. Modificar mesa — 204

**PUT `/api/Mesas/{id}`**, con **M** en el parámetro `id` y en el cuerpo:

```text
{
  "id": M,
  "numero": 180,
  "capacidad": 6,
  "ubicacion": "Terraza actualizada"
}
```

**Esperado:** `204 No Content`, sin cuerpo. Después ejecutar **GET `/api/Mesas/{id}`** con **M**: debe responder **200**, con capacidad **6** y ubicación **Terraza actualizada**.

## 7. ID de ruta diferente del cuerpo — 400

**PUT `/api/Mesas/{id}`**, manteniendo **M** en la ruta:

```json
{
  "id": 2147483647,
  "numero": 180,
  "capacidad": 6,
  "ubicacion": "Prueba"
}
```

**Esperado:** `400 Bad Request`, porque los ID de la ruta y el cuerpo no coinciden.

## 8. Número duplicado al modificar — 409

**PUT `/api/Mesas/{id}`**, con **M** en la ruta y el cuerpo:

```text
{
  "id": M,
  "numero": 1,
  "capacidad": 6,
  "ubicacion": "Prueba"
}
```

**Esperado:** `409 Conflict`, porque el número 1 pertenece a otra mesa. La mesa M conserva el número 180 y su capacidad 6.

## 9. Ruta anidada sin reservas — 200

**GET `/api/Mesas/{id}/reservas`**, con **M** en `id`.

**Esperado:** `200 OK` con `[]`. La mesa existe, pero todavía no tiene reservas.

## 10. Crear reserva — 201

**POST `/api/Reservas`**. Reemplazar **M**:

```text
{
  "nombreCliente": "Cliente de prueba",
  "telefono": "999123456",
  "fechaHora": "2030-12-10T13:00:00",
  "cantidadPersonas": 4,
  "observaciones": "Prueba desde Swagger en la nube",
  "mesaId": M
}
```

**Esperado:** `201 Created`. Anotar el ID generado como **R** y revisar **Location**, que debe apuntar a la reserva creada mediante HTTPS. No es necesario enviar un objeto `mesa`: basta con la clave foránea `mesaId`.

## 11. Consultar reservas — tres solicitudes con 200

Ejecutar cada solicitud por separado:

| Endpoint | Parámetros | Resultado esperado |
|---|---|---|
| GET `/api/Reservas` | Todos los filtros vacíos | **200**, listado que incluye la reserva R. |
| GET `/api/Reservas/{id}` | `id`: **R** | **200**, reserva R con los datos de su mesa M. |
| GET `/api/Mesas/{id}/reservas` | `id`: **M** | **200**, listado de reservas de la mesa que incluye R. |

La mesa incluida en la consulta de reserva no debe contener otra colección `reservas`, evitando ciclos en el JSON.

## 12. Consultar con filtros — 200

En **GET `/api/Reservas`**, completar:

| Parámetro | Valor |
|---|---|
| `mesaId` | **M**, reemplazado por el ID real |
| `desde` | `2030-12-10T00:00:00` |
| `hasta` | `2030-12-10T23:59:59` |

**Esperado:** `200 OK` con la reserva R creada en la prueba 10. El filtro se verifica antes de modificar su fecha en la prueba 18.

## 13. Filtros invertidos — 400

En **GET `/api/Reservas`**, completar:

| Parámetro | Valor |
|---|---|
| `mesaId` | Dejar vacío |
| `desde` | `2030-12-11T00:00:00` |
| `hasta` | `2030-12-10T00:00:00` |

**Esperado:** `400 Bad Request`, porque `desde` es posterior a `hasta`.

## 14. Clave foránea inexistente — 400

**POST `/api/Reservas`**

```json
{
  "nombreCliente": "Cliente de prueba",
  "telefono": "999123456",
  "fechaHora": "2030-12-10T13:00:00",
  "cantidadPersonas": 4,
  "mesaId": 2147483647
}
```

**Esperado:** `400 Bad Request`, porque la mesa indicada no existe.

## 15. Superar capacidad — 409

**POST `/api/Reservas`**. Reemplazar **M**:

```text
{
  "nombreCliente": "Cliente de prueba",
  "telefono": "999123456",
  "fechaHora": "2030-12-10T13:00:00",
  "cantidadPersonas": 7,
  "mesaId": M
}
```

**Esperado:** `409 Conflict`. La mesa tiene capacidad **6** y se intentan registrar **7** personas.

## 16. Eliminar mesa con reservas — 409

**DELETE `/api/Mesas/{id}`**, con **M**.

**Esperado:** `409 Conflict`. La mesa tiene asociada la reserva R y no debe eliminarse.

## 17. Reducir capacidad incompatible — 409

**PUT `/api/Mesas/{id}`**, con **M** en la ruta y el cuerpo:

```text
{
  "id": M,
  "numero": 180,
  "capacidad": 2,
  "ubicacion": "Terraza actualizada"
}
```

**Esperado:** `409 Conflict`. La reserva R es para cuatro personas; la capacidad de la mesa debe conservarse en **6**.

## 18. Modificar reserva — 204

**PUT `/api/Reservas/{id}`**, con **R** en la ruta. Reemplazar **R** y **M** en el cuerpo:

```text
{
  "id": R,
  "nombreCliente": "Cliente actualizado",
  "telefono": "999123456",
  "fechaHora": "2030-12-11T14:00:00",
  "cantidadPersonas": 5,
  "observaciones": "Reserva actualizada desde Swagger",
  "mesaId": M
}
```

**Esperado:** `204 No Content`. Después ejecutar **GET `/api/Reservas/{id}`** con **R**: debe responder **200**, con nombre **Cliente actualizado**, fecha **2030-12-11T14:00:00** y cantidad **5**.

## 19. Errores del PUT de reserva — tres solicitudes

Ejecutar las tres pruebas por separado. Cada cuerpo parte de la reserva válida de la prueba 18.

### 19.1. ID distinto — 400

**PUT `/api/Reservas/{id}`**, con **R** en la ruta y **M** en el cuerpo:

```text
{
  "id": 2147483647,
  "nombreCliente": "Cliente actualizado",
  "telefono": "999123456",
  "fechaHora": "2030-12-11T14:00:00",
  "cantidadPersonas": 5,
  "mesaId": M
}
```

**Esperado:** `400 Bad Request`, por diferencia entre los ID de ruta y cuerpo.

### 19.2. Mesa inexistente — 400

**PUT `/api/Reservas/{id}`**, con **R** en la ruta y el cuerpo:

```text
{
  "id": R,
  "nombreCliente": "Cliente actualizado",
  "telefono": "999123456",
  "fechaHora": "2030-12-11T14:00:00",
  "cantidadPersonas": 5,
  "mesaId": 2147483647
}
```

**Esperado:** `400 Bad Request`, porque la mesa indicada no existe.

### 19.3. Supera capacidad — 409

**PUT `/api/Reservas/{id}`**, con **R** en la ruta. Reemplazar **R** y **M**:

```text
{
  "id": R,
  "nombreCliente": "Cliente actualizado",
  "telefono": "999123456",
  "fechaHora": "2030-12-11T14:00:00",
  "cantidadPersonas": 7,
  "mesaId": M
}
```

**Esperado:** `409 Conflict`. La reserva debe conservar los cinco asistentes de la última modificación correcta.

## 20. Recursos inexistentes — siete solicitudes con 404

Ejecutar estas cinco solicitudes con `id = 2147483647`:

| Método | Ruta | Resultado esperado |
|---|---|---|
| GET | `/api/Mesas/{id}` | **404** |
| GET | `/api/Reservas/{id}` | **404** |
| GET | `/api/Mesas/{id}/reservas` | **404** |
| DELETE | `/api/Mesas/{id}` | **404** |
| DELETE | `/api/Reservas/{id}` | **404** |

### 20.1. Modificar una mesa inexistente — 404

**PUT `/api/Mesas/{id}`**, con `2147483647` en la ruta:

```json
{
  "id": 2147483647,
  "numero": 180,
  "capacidad": 6,
  "ubicacion": "Prueba"
}
```

**Esperado:** `404 Not Found`. Los campos deben ser válidos y el ID del cuerpo debe coincidir con el de la ruta para probar específicamente la inexistencia del recurso.

### 20.2. Modificar una reserva inexistente — 404

**PUT `/api/Reservas/{id}`**, con `2147483647` en la ruta. Reemplazar **M**:

```text
{
  "id": 2147483647,
  "nombreCliente": "Cliente de prueba",
  "telefono": "999123456",
  "fechaHora": "2030-12-11T14:00:00",
  "cantidadPersonas": 4,
  "mesaId": M
}
```

**Esperado:** `404 Not Found`.

## 21. Eliminar los registros de prueba — 204 y comprobación 404

Ejecutar estrictamente en este orden, usando los ID reales **R** y **M**:

| Orden | Solicitud | ID | Resultado esperado |
|---|---|---|---|
| 1 | DELETE `/api/Reservas/{id}` | **R** | **204**, sin cuerpo. |
| 2 | GET `/api/Reservas/{id}` | **R** | **404**, confirma la eliminación. |
| 3 | DELETE `/api/Mesas/{id}` | **M** | **204**, ya no tiene reservas asociadas. |
| 4 | GET `/api/Mesas/{id}` | **M** | **404**, confirma la eliminación. |

Eliminar únicamente los registros creados durante esta guía. Si se conservaban los datos iniciales y no hubo cambios de otros usuarios, al finalizar los GET de mesas y reservas mostrarán nuevamente **cuatro mesas y tres reservas**. Para repetir la guía, crear nuevos registros y anotar sus nuevos ID.

## 22. Estado final — 200

**GET `/api/Estado`**

**Esperado:** `200 OK` con:

```json
{
  "estado": "Disponible",
  "baseDeDatos": "PostgreSQL"
}
```

## Criterios de comprobación

| Código | Qué demuestra la guía |
|---|---|
| **200 OK** | Consulta de listas, recursos, filtros, ruta anidada y estado. |
| **201 Created** | Creación de mesa y reserva con cabecera Location del recurso creado. |
| **204 No Content** | Modificaciones y eliminaciones correctas, sin cuerpo de respuesta. |
| **400 Bad Request** | Validaciones de campos, ID no coincidentes, filtros invertidos y FK inexistente. |
| **404 Not Found** | Recursos inexistentes y confirmación de eliminaciones. |
| **409 Conflict** | Duplicados, dependencias y reglas de capacidad. |

Esta guía describe resultados esperados; no constituye un registro de ejecución ni reemplaza las capturas reales. Si una respuesta difiere de lo indicado, revisar el cuerpo enviado, los ID anotados y el orden de las pruebas antes de continuar.
