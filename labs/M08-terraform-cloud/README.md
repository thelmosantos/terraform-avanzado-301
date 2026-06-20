# M08 — Terraform Cloud y estados remotos

[← Página anterior](../M07-gestion-estado/M07-01-operar-estado.md) · [Siguiente página →](M08-01-migracion-terraform-cloud.md)

> [!NOTE]
> **Cómo funciona este módulo.** Conceptos → recorrido **en la herramienta** → **laboratorio**
> que haces tú → conclusiones, comprobación y reto.

## Qué aprenderás

- Por qué el estado local no escala a un equipo.
- Migrar el estado a **Terraform Cloud** (backend remoto).
- Usar **workspaces**, **locking** y trabajar en colaboración sin pisarse.

## Contexto

- Terraform Cloud es el cajón compartido con candado: solo uno aplica a la vez.
- El estado remoto + locking elimina los conflictos de `.tfstate`.
- Las credenciales AWS se configuran como variables del workspace en TFC.

> [!IMPORTANT]
> Este módulo ejecuta `apply` (vía TFC) sobre AWS. Hazlo en sesión y destruye al terminar.

## Tabla de ejercicios

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M08-01 | [Migración a Terraform Cloud](M08-01-migracion-terraform-cloud.md) | Migrar el estado local a TFC, ver el workspace, el run y el bloqueo |

→ Empieza por **[M08-01 — Migración a Terraform Cloud](M08-01-migracion-terraform-cloud.md)**.
