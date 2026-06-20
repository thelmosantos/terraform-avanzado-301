# M11 — Seguridad y gestión de secretos

[← Página anterior](../M10-cicd-github-actions/M10-01-pipeline-terraform.md) · [Siguiente página →](M11-01-oidc-minimo-privilegio.md)

> [!NOTE]
> **Cómo funciona este módulo.** Conceptos → recorrido **en la herramienta** → **laboratorio**
> que haces tú → conclusiones, comprobación y reto.

## Qué aprenderás

- Marcar variables como **sensibles** y gestionar secretos con **GitHub Secrets**.
- Aplicar **IAM** con principio de **mínimo privilegio**.
- Eliminar credenciales estáticas con **OIDC GitHub↔AWS** (roles asumibles, tokens efímeros).

## Contexto

- OIDC es enseñar tu carnet (token efímero) en vez de dejar una copia de la llave (clave estática).
- La trust policy del rol debe acotar repo y rama: ni de menos (no asume) ni de más (inseguro).
- Objetivo: **cero claves de AWS** en el repositorio.

> [!IMPORTANT]
> Este módulo crea roles IAM y asume identidades en AWS. Hazlo en sesión y limpia al terminar.

## Tabla de ejercicios

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M11-01 | [OIDC y mínimo privilegio](M11-01-oidc-minimo-privilegio.md) | Configurar OIDC GitHub↔AWS y acotar permisos al mínimo |

→ Empieza por **[M11-01 — OIDC y mínimo privilegio](M11-01-oidc-minimo-privilegio.md)**.
