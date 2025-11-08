# API de Pedidos

Este documento describe los endpoints para la gestión de pedidos. Todos los endpoints requieren autenticación.

## Endpoints

### 1. Listar Pedidos

*   **URL:** `/api/pedidos`
*   **Método:** `GET`
*   **Descripción:** Obtiene una lista de todos los pedidos.
*   **Acceso:** `admin`, `mesero`, `cocinero`
*   **Respuesta Exitosa (200 OK):**

```json
[
    {
        "id": 1,
        "mesa_id": 5,
        "usuario_id": 2,
        "estado": "pendiente",
        "total": 150.00,
        "createdAt": "2023-11-08T12:00:00.000Z"
    }
]
```

### 2. Crear un Pedido

*   **URL:** `/api/pedidos`
*   **Método:** `POST`
*   **Descripción:** Crea un nuevo pedido.
*   **Acceso:** `admin`, `mesero`
*   **Cuerpo de la Solicitud (Request Body):**

| Campo | Tipo | Descripción | Requerido |
| :--- | :--- | :--- | :--- |
| `mesa_id` | Integer | ID de la mesa. | Sí |
| `detalles` | Array | Lista de platillos del pedido. | Sí |

*   **Ejemplo de `detalles`:**

```json
[
    { "platillo_id": 1, "cantidad": 2 },
    { "platillo_id": 3, "cantidad": 1, "notas": "Sin cebolla" }
]
```

*   **Respuesta Exitosa (201 Created):**

```json
{
    "id": 2,
    "mesa_id": 3,
    "usuario_id": 2,
    "estado": "pendiente",
    "total": 250.50,
    "createdAt": "2023-11-08T12:30:00.000Z",
    "detalles": [
        {
            "id": 3,
            "platillo_id": 1,
            "cantidad": 2,
            "precio_unitario": 75.00
        },
        {
            "id": 4,
            "platillo_id": 3,
            "cantidad": 1,
            "precio_unitario": 100.50,
            "notas": "Sin cebolla"
        }
    ]
}
```

### 3. Actualizar Estado de un Pedido

*   **URL:** `/api/pedidos/:id/estado`
*   **Método:** `PATCH`
*   **Descripción:** Actualiza el estado de un pedido (`pendiente`, `en_preparacion`, `listo`, `entregado`, `cancelado`).
*   **Acceso:** `admin`
*   **Cuerpo de la Solicitud (Request Body):**

| Campo | Tipo | Descripción | Requerido |
| :--- | :--- | :--- | :--- |
| `estado` | String | Nuevo estado del pedido. | Sí |

*   **Respuesta Exitosa (200 OK):**

```json
{
    "id": 1,
    "estado": "en_preparacion"
}
```

### 4. Eliminar un Pedido

*   **URL:** `/api/pedidos/:id`
*   **Método:** `DELETE`
*   **Descripción:** Elimina un pedido.
*   **Acceso:** `admin`
*   **Respuesta Exitosa (204 No Content):**