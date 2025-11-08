# API de Detalle de Pedido

Este documento describe los endpoints para gestionar los detalles (platillos) de un pedido específico. Todos los endpoints requieren autenticación.

## Endpoints

### 1. Listar Detalles de un Pedido

*   **URL:** `/api/detalles-pedido/:pedido_id`
*   **Método:** `GET`
*   **Descripción:** Obtiene todos los platillos de un pedido específico.
*   **Acceso:** `admin`, `mesero`, `cocinero`
*   **Respuesta Exitosa (200 OK):**

```json
[
    {
        "id": 1,
        "pedido_id": 1,
        "platillo_id": 5,
        "cantidad": 2,
        "precio_unitario": 120.00,
        "notas": "Extra picante"
    }
]
```

### 2. Agregar Detalle a un Pedido

*   **URL:** `/api/detalles-pedido/:pedido_id`
*   **Método:** `POST`
*   **Descripción:** Agrega un nuevo platillo a un pedido existente.
*   **Acceso:** `admin`, `mesero`
*   **Cuerpo de la Solicitud (Request Body):**

| Campo | Tipo | Descripción | Requerido |
| :--- | :--- | :--- | :--- |
| `platillo_id` | Integer | ID del platillo a agregar. | Sí |
| `cantidad` | Integer | Cantidad del platillo. | Sí |
| `notas` | String | Notas adicionales para la cocina. | Opcional |

*   **Respuesta Exitosa (201 Created):**

```json
{
    "id": 2,
    "pedido_id": 1,
    "platillo_id": 3,
    "cantidad": 1,
    "precio_unitario": 95.00,
    "notas": "Sin queso"
}
```

### 3. Actualizar un Detalle de Pedido

*   **URL:** `/api/detalles-pedido/:id`
*   **Método:** `PUT`
*   **Descripción:** Actualiza la cantidad o las notas de un platillo en un pedido.
*   **Acceso:** `admin`
*   **Cuerpo de la Solicitud (Request Body):**

| Campo | Tipo | Descripción | Requerido |
| :--- | :--- | :--- | :--- |
| `cantidad` | Integer | Nueva cantidad del platillo. | Opcional |
| `notas` | String | Nuevas notas para el platillo. | Opcional |

*   **Respuesta Exitosa (200 OK):**

```json
{
    "id": 2,
    "cantidad": 2,
    "notas": "Sin queso y sin crema"
}
```

### 4. Eliminar un Detalle de Pedido

*   **URL:** `/api/detalles-pedido/:id`
*   **Método:** `DELETE`
*   **Descripción:** Elimina un platillo de un pedido.
*   **Acceso:** `admin`
*   **Respuesta Exitosa (204 No Content):**