# API de Usuarios

Este documento describe los endpoints para la gestión de usuarios. Todos los endpoints requieren autenticación y rol de `admin`.

## Endpoints

### 1. Listar Usuarios

*   **URL:** `/api/usuarios`
*   **Método:** `GET`
*   **Descripción:** Obtiene una lista de todos los usuarios.
*   **Acceso:** `admin`
*   **Respuesta Exitosa (200 OK):**

```json
[
    {
        "id": 1,
        "nombre": "Usuario Admin",
        "email": "admin@example.com",
        "rol": "admin"
    },
    {
        "id": 2,
        "nombre": "Usuario Mesero",
        "email": "mesero@example.com",
        "rol": "mesero"
    }
]
```

### 2. Obtener un Usuario

*   **URL:** `/api/usuarios/:id`
*   **Método:** `GET`
*   **Descripción:** Obtiene un usuario específico por su ID.
*   **Acceso:** `admin`
*   **Respuesta Exitosa (200 OK):**

```json
{
    "id": 1,
    "nombre": "Usuario Admin",
    "email": "admin@example.com",
    "rol": "admin"
}
```

*   **Respuesta de Error:**
    *   `404 Not Found`: Si el usuario no existe.

### 3. Actualizar un Usuario

*   **URL:** `/api/usuarios/:id`
*   **Método:** `PUT`
*   **Descripción:** Actualiza los datos de un usuario.
*   **Acceso:** `admin`
*   **Cuerpo de la Solicitud (Request Body):**

| Campo | Tipo | Descripción | Requerido |
| :--- | :--- | :--- | :--- |
| `nombre` | String | Nuevo nombre del usuario. | Opcional |
| `email` | String | Nuevo correo del usuario. | Opcional |
| `password` | String | Nueva contraseña del usuario. | Opcional |
| `rol` | String | Nuevo rol del usuario. | Opcional |

*   **Respuesta Exitosa (200 OK):**

```json
{
    "id": 1,
    "nombre": "Nuevo Nombre",
    "email": "nuevo@example.com",
    "rol": "admin"
}
```

### 4. Eliminar un Usuario

*   **URL:** `/api/usuarios/:id`
*   **Método:** `DELETE`
*   **Descripción:** Elimina un usuario.
*   **Acceso:** `admin`
*   **Respuesta Exitosa (204 No Content):**
*   **Respuesta de Error:**
    *   `404 Not Found`: Si el usuario no existe.