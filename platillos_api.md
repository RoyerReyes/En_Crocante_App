# Documentación API de Platillos

Esta es la documentación para el endpoint de `/api/platillos`.

## Endpoints

La URL base para estos endpoints es `http://<tu-servidor>:<puerto>/api/platillos`.

### 1. Listar todos los platillos

- **Endpoint:** `GET /`
- **Descripción:** Obtiene una lista de todos los platillos disponibles.
- **Autenticación:** Requerida. Roles permitidos: `admin`, `mesero`.
- **Header de autorización:** `Authorization: Bearer <token>`
- **Respuesta exitosa (200 OK):**

```json
[
  {
    "id": 1,
    "nombre": "Tacos al Pastor",
    "descripcion": "Deliciosos tacos de cerdo marinado con piña.",
    "precio": 15.50,
    "imagenUrl": "http://tu-api.com/images/tacos.jpg",
    "activo": true,
    "categoria": {
      "id": 2,
      "nombre": "Principales"
    }
  },
  {
    "id": 2,
    "nombre": "Guacamole",
    "descripcion": "Aguacate fresco machacado con cebolla, cilantro y chile.",
    "precio": 8.00,
    "imagenUrl": "http://tu-api.com/images/guacamole.jpg",
    "activo": true,
    "categoria": {
      "id": 1,
      "nombre": "Entradas"
    }
  }
]
```

### 2. Obtener un platillo por ID

- **Endpoint:** `GET /:id`
- **Descripción:** Obtiene un platillo específico por su ID.
- **Autenticación:** Requerida. Roles permitidos: `admin`, `mesero`.
- **Header de autorización:** `Authorization: Bearer <token>`
- **Parámetros de URL:**
  - `id` (requerido): El ID del platillo a obtener.
- **Respuesta exitosa (200 OK):**

```json
{
  "id": 1,
  "nombre": "Tacos al Pastor",
  "descripcion": "Deliciosos tacos de cerdo marinado con piña.",
  "precio": 15.50,
  "imagenUrl": "http://tu-api.com/images/tacos.jpg",
  "activo": true,
  "categoria": {
    "id": 2,
    "nombre": "Principales"
  }
}
```

- **Respuesta de error (404 Not Found):**

```json
{
  "message": "Platillo no encontrado"
}
```

### 3. Crear un nuevo platillo

- **Endpoint:** `POST /`
- **Descripción:** Crea un nuevo platillo.
- **Autenticación:** Requerida. Solo rol `admin`.
- **Header de autorización:** `Authorization: Bearer <token>`
- **Cuerpo de la solicitud (JSON):**

```json
{
  "nombre": "Nuevo Platillo",
  "descripcion": "Descripción del nuevo platillo.",
  "precio": 12.99,
  "imagenUrl": "http://tu-api.com/images/nuevo.jpg",
  "activo": true,
  "categoria_id": 3
}
```

- **Respuesta exitosa (201 Created):**

```json
{
  "message": "Platillo creado 🚀",
  "platillo": {
    "id": 3,
    "nombre": "Nuevo Platillo",
    "descripcion": "Descripción del nuevo platillo.",
    "precio": 12.99,
    "imagenUrl": "http://tu-api.com/images/nuevo.jpg",
    "activo": true,
    "categoria_id": 3
  }
}
```

### 4. Actualizar un platillo

- **Endpoint:** `PUT /:id`
- **Descripción:** Actualiza un platillo existente.
- **Autenticación:** Requerida. Solo rol `admin`.
- **Header de autorización:** `Authorization: Bearer <token>`
- **Parámetros de URL:**
  - `id` (requerido): El ID del platillo a actualizar.
- **Cuerpo de la solicitud (JSON):**

```json
{
  "nombre": "Platillo Actualizado",
  "precio": 14.50
}
```

- **Respuesta exitosa (200 OK):**

```json
{
  "message": "Platillo actualizado ✅"
}
```

- **Respuesta de error (404 Not Found):**

```json
{
  "message": "Platillo no encontrado"
}
```

### 5. Eliminar un platillo

- **Endpoint:** `DELETE /:id`
- **Descripción:** Elimina un platillo.
- **Autenticación:** Requerida. Solo rol `admin`.
- **Header de autorización:** `Authorization: Bearer <token>`
- **Parámetros de URL:**
  - `id` (requerido): El ID del platillo a eliminar.
- **Respuesta exitosa (200 OK):**

```json
{
  "message": "Platillo eliminado 🗑️"
}
```

- **Respuesta de error (404 Not Found):**

```json
{
  "message": "Platillo no encontrado"
}
```
