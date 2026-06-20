# M14-01 — Plataforma IaC integradora

[← Página anterior](README.md) · [Volver al índice →](../../README.md)

Este es el proyecto que reúne todo el curso. En equipo, construís un repositorio que combina
estructura multi-entorno, módulos versionados, estado remoto, CI/CD con OIDC, refactor seguro e
integración con Ansible. Al terminar tendréis una **plataforma IaC** reutilizable como base de
futuros proyectos.

> [!IMPORTANT]
> El proyecto despliega sobre AWS. Trabajad dentro de la sesión y ejecutad `terraform destroy` al
> terminar. Repartid el trabajo por bloques y haced *time-box*: mejor terminado que perfecto.

### Objetivos

- Integrar lo aprendido en M02–M13 en un único repositorio operativo.
- Operar el ciclo completo: rama → PR → `plan` → aprobación → `apply`.
- Entregar una plataforma con estado remoto, módulos, CI/CD seguro y configuración con Ansible.

---

## Conceptos

No hay conceptos nuevos: el reto es **encajar las piezas** que ya conoces.

| Bloque | Módulo de origen |
|--------|------------------|
| Estructura dev/test/prod | M02 |
| Flujo Git + PR | M03 |
| Módulos reutilizables y versionados | M04, M05 |
| Expresiones dinámicas | M06 |
| Estado (operación + remoto en TFC) | M07, M08 |
| Import / refactor con `moved` | M09 |
| CI/CD con GitHub Actions | M10 |
| Seguridad: OIDC + mínimo privilegio | M11 |
| Provisión + configuración con Ansible | M13 |

> [!NOTE]
> Repartid roles en el equipo (módulos, pipeline, seguridad, Ansible) y mezclad por PRs: es la
> forma de trabajar de un equipo de plataforma real.

## En la herramienta

Usaréis todas las interfaces del curso de forma combinada: **GitHub** (PRs, Actions),
**Terraform Cloud** (estado y runs) y la **consola de AWS** (recursos creados). El recorrido es el
ciclo de vida completo de un cambio de infraestructura, de la rama al `apply` aprobado.

## Laboratorio

### Objetivo

Construir y operar la plataforma IaC integradora en equipo.

### En qué consiste

Montáis el repositorio combinando los bloques y lo operáis end-to-end con un cambio real.

### 1 — Estructura y módulos

**Acción:** Partid de la estructura multi-entorno (M02) y consumid los módulos versionados
(naming, tagging, S3) por `ref` (M04, M05).
**Por qué:** Base ordenada y reutilizable.
**Resultado esperado:** `environments/{dev,test}` consumen módulos pineados por versión.

### 2 — Estado remoto en Terraform Cloud

**Acción:** Configurad el backend `cloud` con un workspace por entorno (M08) y las credenciales
como variables sensibles del workspace.
**Por qué:** Estado compartido con locking para trabajar en equipo.
**Resultado esperado:** El estado vive en TFC; los runs quedan registrados.

### 3 — Pipeline CI/CD con OIDC

**Acción:** Añadid el workflow (M10) con `fmt`/`validate`/`plan` en PR y `apply` aprobado en el
merge, autenticando por **OIDC** (M11) sin secretos estáticos.
**Por qué:** Despliegues automatizados, auditables y sin claves de larga vida.
**Resultado esperado:** Una PR dispara `plan`; el merge pide aprobación y aplica vía rol OIDC.

### 4 — Un cambio real end-to-end

**Acción:** Implementad un cambio (p. ej. añadir un bucket parametrizado con `for_each`, M06) por
rama → PR → revisión → merge → apply aprobado.
**Por qué:** Demostráis el ciclo completo de cambio controlado.
**Resultado esperado:** El cambio llega a AWS solo tras revisión y aprobación.

### 5 — Capa de configuración con Ansible (opcional según tiempo)

**Acción:** Si creáis una EC2, configuradla con Ansible a partir de los outputs (M13).
**Por qué:** Cerráis el círculo provisión + configuración.
**Resultado esperado:** Servicio configurado sobre la instancia provisionada.

### 6 — Refactor seguro y limpieza

**Acción:** Practicad un `moved` para renombrar un recurso sin recrearlo (M09) y, al terminar,
`terraform destroy` de todo.
**Por qué:** Evolución sin impacto y cuidado de la ventana/coste.
**Resultado esperado:** Refactor sin destruir/crear y entorno limpio.

## Conclusiones

- Tenéis una **plataforma IaC** que integra estructura, módulos, estado remoto, CI/CD seguro y configuración.
- El cambio de infraestructura sigue un ciclo controlado: rama → PR → plan → aprobación → apply.
- El repositorio queda como **base reutilizable** para proyectos futuros.

## Comprueba tu entendimiento

**Ciclo completo operativo**
Abrid una PR con un cambio y seguidla hasta el `apply`.
→ El cambio solo llega a AWS tras `plan` revisado y aprobación.

**Sin credenciales estáticas**
Revisad los secretos del repo y el workflow.
→ El pipeline usa OIDC; no hay claves de AWS almacenadas.

**Estado remoto**
Mirad el workspace en Terraform Cloud.
→ El estado y los runs están en TFC, no en local.

## Reto

### 1 — Promoción dev → prod

¿Cómo promoverías un cambio validado en `dev` a `prod` minimizando el riesgo?

<details>
<summary>Ver solución</summary>

Mismo código, **workspaces/variables por entorno**: aplicas primero en `dev`, revisas el `plan` de
`prod` en una PR (con aprobación de environment más estricta) y solo entonces aplicas en `prod`.
La promoción es de **configuración** (variables), no de copiar y pegar código.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| El equipo se pisa en el estado | Estado local en vez de remoto | Usad TFC con un workspace por entorno (locking) |
| El pipeline no asume el rol | `sub` de OIDC o `permissions: id-token` mal | Revisad trust policy y permisos del job (M11) |
| Cambios incompatibles entre módulos | Consumís `main` en vez de tags | Pinead `?ref=vX.Y.Z` (M05) |
| Recursos vivos al acabar | Falta `destroy` | `terraform destroy` en cada entorno antes de cerrar |
