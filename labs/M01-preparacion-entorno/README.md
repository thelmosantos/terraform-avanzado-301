# M01 — Preparación del entorno

[← Página anterior](../../README.md) · [Siguiente página →](M01-01-entorno-verificado.md)

> [!NOTE]
> **Cómo funciona este módulo.** Primero los **conceptos** (qué piezas vas a usar y por qué),
> luego ves **en la herramienta** el recorrido completo, y después lo repites tú en el
> **laboratorio**. Cerramos con conclusiones, una comprobación y un reto.

## Qué aprenderás

- Para qué sirve cada pieza: **fork**, **dev container** (Codespaces o local), **Terraform Cloud**.
- Las **distintas vías** de inyectar credenciales de AWS (Codespaces secrets, `.env` local, asunción de rol).
- Cómo **verificar** identidad, herramientas y, sobre todo, que tienes los **permisos** necesarios.

## Contexto

- No instalarás nada: el **dev container** ya trae Terraform, AWS CLI, Ansible y tflint.
- Partirás de un **fork** del repositorio base, que harás crecer durante el curso.
- La cuenta **AWS** solo está disponible alrededor del horario de clase: verifica el acceso al empezar.
- Un **tester de permisos** confirma que tu cuenta es apta antes de construir nada.

## Tabla de ejercicios

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M01-01 | [Entorno verificado](M01-01-entorno-verificado.md) | Abrir el dev container, inyectar credenciales y verificar identidad, tooling y permisos |

→ Empieza por **[M01-01 — Entorno verificado](M01-01-entorno-verificado.md)**.
