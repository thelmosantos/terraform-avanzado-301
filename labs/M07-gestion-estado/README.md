# M07 — Gestión avanzada del estado

[← Página anterior](../M06-expresiones-avanzadas/M06-01-expresiones-dinamicas.md) · [Siguiente página →](M07-01-operar-estado.md)

> [!NOTE]
> **Cómo funciona este módulo.** Conceptos → recorrido **en la herramienta** → **laboratorio**
> que haces tú → conclusiones, comprobación y reto.

## Qué aprenderás

- Qué guarda el **state** y cómo está estructurado por dentro.
- Operar el estado con `terraform state list/show/mv/rm`.
- Detectar y analizar **drift** (cambios hechos fuera de Terraform).

## Contexto

- El state es la **memoria** de Terraform: el inventario de lo que gestiona.
- `state mv` renombra sin recrear; `state rm` olvida sin destruir.
- Nunca edites el `.tfstate` a mano: usa siempre los comandos.

> [!IMPORTANT]
> Este módulo crea recursos en AWS. Hazlo durante la sesión y ejecuta `terraform destroy` al terminar.

## Tabla de ejercicios

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M07-01 | [Operar el estado](M07-01-operar-estado.md) | Inspeccionar, mover y eliminar del estado, y detectar drift |

→ Empieza por **[M07-01 — Operar el estado](M07-01-operar-estado.md)**.
