# Terraform Avanzado: DevOps e IaC

[Siguiente página →](labs/M01-preparacion-entorno/README.md)

Formación **100 % práctica**. A lo largo del curso, tu repositorio evoluciona laboratorio a
laboratorio hasta convertirse en una **plataforma de Infraestructura como Código** completa.

> [!NOTE]
> El objetivo es dominar **Terraform**, no AWS. Usamos AWS solo como proveedor de referencia
> para ejecutar los laboratorios, priorizando recursos de capa gratuita o de muy bajo coste.
> Lo que aprendas aquí te sirve con cualquier proveedor.

## Cómo funciona el curso

Sigue este README como índice y avanza **página a página** con **← Página anterior · Siguiente página →**.

Cada módulo sigue el mismo ritmo:

1. **Conceptos** — la idea mínima necesaria.
2. **En la herramienta** — el recorrido que verás en vivo (Codespaces, Terraform CLI, Terraform Cloud, GitHub).
3. **Laboratorio** — lo haces tú, paso a paso.
4. **Conclusiones · Comprueba tu entendimiento · Reto · Errores frecuentes**.

## Entorno de trabajo

Todo el tooling viene en un **dev container** (`.devcontainer/`): ábrelo en **GitHub Codespaces**
o en **local** con Docker (*Reopen in Container*). No instalas nada a mano.

| Pieza | Para qué |
|-------|----------|
| **Fork** del repo base | Tu copia del proyecto, que irás haciendo crecer |
| **Dev container** | Entorno reproducible con Terraform, AWS CLI, Ansible y tflint ya instalados |
| **Terraform CLI** | Ejecutar `init`, `plan`, `apply`, `state`… |
| **Terraform Cloud** | Estado remoto, workspaces y colaboración |
| **GitHub Actions** | Automatizar el ciclo de vida (CI/CD) |
| **Cuenta AWS** | Proveedor de referencia para ejecutar los labs |

Las **credenciales** las pones tú (aprenderás varias vías en M01): *secrets* de Codespaces o un
`.env` local. Nunca van dentro del repositorio.

> [!IMPORTANT]
> La cuenta AWS del curso solo está disponible **alrededor del horario de clase**. Ejecuta los
> laboratorios que crean recursos durante la sesión y recuerda **destruirlos al terminar**
> (`terraform destroy`): cuida la ventana de acceso y el coste.

## Antes de empezar

| Requisito | Dónde |
|-----------|--------|
| Preparar el entorno | **[M01 — Preparación del entorno](labs/M01-preparacion-entorno/README.md)** |
| Conocimientos previos | Linux y CLI básicos, Git básico, nociones de cloud y de Terraform |

## Módulos

| # | Módulo | Índice |
|---|--------|--------|
| M01 | Preparación del entorno | [labs/M01-preparacion-entorno/](labs/M01-preparacion-entorno/README.md) |
| M02 | Organización profesional de proyectos | [labs/M02-organizacion-proyectos/](labs/M02-organizacion-proyectos/README.md) |
| M03 | Git aplicado a IaC | [labs/M03-git-iac/](labs/M03-git-iac/README.md) |
| M04 | Módulos reutilizables | [labs/M04-modulos-reutilizables/](labs/M04-modulos-reutilizables/README.md) |
| M05 | Versionado y distribución de módulos | [labs/M05-versionado-modulos/](labs/M05-versionado-modulos/README.md) |
| M06 | Expresiones avanzadas | [labs/M06-expresiones-avanzadas/](labs/M06-expresiones-avanzadas/README.md) |
| M07 | Gestión avanzada del estado | [labs/M07-gestion-estado/](labs/M07-gestion-estado/README.md) |
| M08 | Terraform Cloud y estados remotos | [labs/M08-terraform-cloud/](labs/M08-terraform-cloud/README.md) |
| M09 | Importación y refactorización | [labs/M09-importacion-refactorizacion/](labs/M09-importacion-refactorizacion/README.md) |
| M10 | CI/CD con GitHub Actions | [labs/M10-cicd-github-actions/](labs/M10-cicd-github-actions/README.md) |
| M11 | Seguridad y gestión de secretos | [labs/M11-seguridad-secretos/](labs/M11-seguridad-secretos/README.md) |
| M12 | Troubleshooting y recuperación | [labs/M12-troubleshooting/](labs/M12-troubleshooting/README.md) |
| M13 | Terraform + Ansible | [labs/M13-terraform-ansible/](labs/M13-terraform-ansible/README.md) |
| M14 | Caso práctico integrador | [labs/M14-caso-integrador/](labs/M14-caso-integrador/README.md) |

## Empieza aquí

→ **[M01 — Preparación del entorno](labs/M01-preparacion-entorno/README.md)**
