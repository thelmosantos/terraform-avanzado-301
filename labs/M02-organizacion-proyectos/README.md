# M02 — Organización profesional de proyectos

[← Página anterior](../M01-preparacion-entorno/M01-01-entorno-verificado.md) · [Siguiente página →](M02-01-estructura-multientorno.md)

> [!NOTE]
> **Cómo funciona este módulo.** Primero los **conceptos** de organización de un proyecto IaC,
> luego ves **en la herramienta** cómo se recorre la estructura, y después la construyes tú en
> el **laboratorio**. Cerramos con conclusiones, comprobación y reto.

## Qué aprenderás

- Cómo estructurar un repositorio Terraform pensado para **varios entornos** (dev/test/prod).
- Cómo separar lo común del código de lo que cambia por entorno (**variables**).
- Convenciones de **nomenclatura** y buenas prácticas organizativas.

## Contexto

- Un proyecto de juguete cabe en un solo archivo; uno real, no: necesita estructura.
- La meta es **no duplicar** código por entorno, sino parametrizarlo.
- Esta organización es la base sobre la que montaremos módulos (M04), estado remoto (M08) y CI/CD (M10).
- Trabajo principalmente **local** (editor + `terraform fmt`/`validate`): no consume AWS.

## Tabla de ejercicios

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M02-01 | [Estructura multi-entorno](M02-01-estructura-multientorno.md) | Montar un layout dev/test/prod con variables por entorno y validarlo |

→ Empieza por **[M02-01 — Estructura multi-entorno](M02-01-estructura-multientorno.md)**.
