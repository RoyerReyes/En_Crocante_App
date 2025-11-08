# API de Autenticación

Este documento describe los endpoints para el registro y la autenticación de usuarios.

## Endpoints

### 1. Registro de Usuario

*   **URL:** `/api/auth/register`
*   **Método:** `POST`
*   **Descripción:** Registra un nuevo usuario en el sistema.
*   **Acceso:** Público
*   **Cuerpo de la Solicitud (Request Body):**

| Campo | Tipo | Descripción | Requerido |
| :--- | :--- | :--- | :--- |
| `nombre` | String | Nombre del usuario. | Sí |
| `email` | String | Correo electrónico del usuario. Debe ser único. | Sí |
| `password` | String | Contraseña del usuario. Mínimo 6 caracteres. | Sí |
| `rol` | String | Rol del usuario (`admin`, `mesero`, `cocinero`). | Sí |

*   **Respuesta Exitosa (201 Created):**

```json
{
    "id": 1,
    "nombre": "Nombre de Usuario",
    "email": "usuario@example.com",
    "rol": "mesero"
}
```

*   **Respuestas de Error:**
    *   `400 Bad Request`: Si los datos de entrada son inválidos (ej. email con formato incorrecto, contraseña corta).
    *   `409 Conflict`: Si el correo electrónico ya está registrado.

### 2. Inicio de Sesión (Login)

*   **URL:** `/api/auth/login`
*   **Método:** `POST`
*   **Descripción:** Autentica a un usuario y devuelve un token JWT.
*   **Acceso:** Público
*   **Cuerpo de la Solicitud (Request Body):**

| Campo | Tipo | Descripción | Requerido |
| :--- | :--- | :--- | :--- |
| `email` | String | Correo electrónico del usuario. | Sí |
| `password` | String | Contraseña del usuario. | Sí |

*   **Respuesta Exitosa (200 OK):**

```json
{
    "token": "ey...",
    "usuario": {
        "id": 1,
        "nombre": "Nombre de Usuario",
        "email": "usuario@example.com",
        "rol": "mesero"
    }
}
```

*   **Respuestas de Error:**
    *   `400 Bad Request`: Si los datos de entrada son inválidos.
    *   `401 Unauthorized`: Si las credenciales son incorrectas.