# M10 — CI/CD con GitHub Actions

[← Página anterior](../M09-importacion-refactorizacion/M09-01-import-moved.md) · [Siguiente página →](M10-01-pipeline-terraform.md)

> [!NOTE]
> **Cómo funciona este módulo.** Conceptos → recorrido **en la herramienta** → **laboratorio**
> que haces tú → conclusiones, comprobación y reto.

## Qué aprenderás

- Aplicar CI/CD a Terraform con **GitHub Actions**.
- Separar `plan` (en la PR) de `apply` (en el merge), con aprobación manual.
- Gestionar variables y secretos dentro del pipeline.

## Contexto

- El pipeline ejecuta siempre los mismos pasos, sin olvidos: `fmt` → `validate` → `plan` → aprobación → `apply`.
- Plan en la PR, apply en el merge: nada de aplicar a mano en prod.
- Las credenciales estáticas en el repo son deuda; las eliminamos en M11 con OIDC.

> [!IMPORTANT]
> El pipeline aplica sobre AWS. Ejecútalo en sesión y destruye los recursos al terminar.

## Tabla de ejercicios

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M10-01 | [Pipeline de Terraform](M10-01-pipeline-terraform.md) | Crear un workflow con `fmt`/`validate`/`plan` en PR y `apply` con aprobación en el merge |

→ Empieza por **[M10-01 — Pipeline de Terraform](M10-01-pipeline-terraform.md)**.
