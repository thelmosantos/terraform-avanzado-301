# M09 — Importación y refactorización

[← Página anterior](../M08-terraform-cloud/M08-01-migracion-terraform-cloud.md) · [Siguiente página →](M09-01-import-moved.md)

> [!NOTE]
> **Cómo funciona este módulo.** Conceptos → recorrido **en la herramienta** → **laboratorio**
> que haces tú → conclusiones, comprobación y reto.

## Qué aprenderás

- Adoptar recursos existentes con `terraform import` (y bloques `import {}`).
- Refactorizar y renombrar recursos sin recrearlos usando `moved {}`.
- Evolucionar infraestructuras de producción sin impacto.

## Contexto

- No todo nace en Terraform: a veces hay que **adoptar** lo que ya existe.
- Primero escribes el recurso en HCL, **luego** lo importas.
- `moved` evita el destroy/create al renombrar.

> [!IMPORTANT]
> Este módulo crea y adopta recursos en AWS. Hazlo en sesión y destruye al terminar.

## Tabla de ejercicios

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M09-01 | [Import y moved](M09-01-import-moved.md) | Adoptar un recurso existente con `import` y refactorizar con `moved` |

→ Empieza por **[M09-01 — Import y moved](M09-01-import-moved.md)**.
