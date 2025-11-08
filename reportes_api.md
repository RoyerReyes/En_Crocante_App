# API de Reportes

Este documento describe los endpoints para la generación de reportes. Todos los endpoints requieren autenticación y rol de `admin`.

## Endpoints

### 1. Reporte de Platillos Más Vendidos

*   **URL:** `/api/reportes/platillos-mas-vendidos`
*   **Método:** `GET`
*   **Descripción:** Obtiene un ranking de los platillos más vendidos.
*   **Acceso:** `admin`
*   **Respuesta Exitosa (200 OK):**

```json
[
    {
        "platillo_id": 5,
        "nombre": "Tacos al Pastor",
        "total_vendido": "150"
    },
    {
        "platillo_id": 2,
        "nombre": "Guacamole",
        "total_vendido": "95"
    }
]
```

### 2. Reporte de Ventas

*   **URL:** `/api/reportes/ventas`
*   **Método:** `GET`
*   **Descripción:** Obtiene un reporte de ventas por período.
*   **Acceso:** `admin`
*   **Query Params:**

| Param | Tipo | Descripción | Opciones | Default |
| :--- | :--- | :--- | :--- | :--- |
| `periodo` | String | El período de tiempo para el reporte. | `diario`, `semanal`, `mensual` | `diario` |

*   **Respuesta Exitosa (200 OK) - Ejemplo Diario:**

```json
{
    "periodo": "diario",
    "fecha": "2023-11-08",
    "total_ventas": "5430.50"
}
```

### 3. Reporte de Ingresos por Platillo

*   **URL:** `/api/reportes/platillos-por-ingresos`
*   **Método:** `GET`
*   **Descripción:** Obtiene un ranking de los platillos que más ingresos han generado.
*   **Acceso:** `admin`
*   **Respuesta Exitosa (200 OK):**

```json
[
    {
        "platillo_id": 5,
        "nombre": "Tacos al Pastor",
        "ingresos_generados": "18000.00"
    },
    {
        "platillo_id": 10,
        "nombre": "Arrachera",
        "ingresos_generados": "15500.50"
    }
]
```