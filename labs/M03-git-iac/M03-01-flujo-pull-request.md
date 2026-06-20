# M03-01 — Flujo de Pull Request

[← Página anterior](README.md) · [Siguiente página →](../M04-modulos-reutilizables/README.md)

Trabajar Terraform en equipo significa que nadie aplica cambios "a lo loco" sobre `main`: cada
cambio entra por una rama, se revisa en un Pull Request y se mezcla cuando está validado. En este
laboratorio recorres ese flujo de principio a fin sobre tu propio repositorio. Es trabajo de Git,
así que no consume AWS y puedes repetirlo cuando quieras.

### Objetivos

- Crear una **rama** para un cambio de infraestructura y abrir un **Pull Request**.
- Revisar el cambio y **resolver un conflicto** de código.
- Entender por qué el **estado** no se mezcla como el código.

---

## Conceptos

En IaC, el flujo de Git es el mismo que en cualquier proyecto serio, con un matiz importante:

| Elemento | Idea |
|----------|------|
| **Rama** | Aíslas tu cambio del código estable (`main`). |
| **Pull Request (PR)** | Propones el cambio para que alguien lo revise antes de mezclar. |
| **Revisión** | Otra persona valida el `plan` y el código antes del merge. |
| **Conflicto de código** | Dos ramas tocan las mismas líneas; se resuelve editando el archivo. |

> [!IMPORTANT]
> **Código vs estado.** El **código** (`.tf`) se mezcla con Git sin problema. El **estado**
> (`.tfstate`) NO: si dos personas aplican a la vez, no se resuelve "a mano", sino con estado
> remoto y bloqueo (lo verás en M07 y M08). Confundir ambos es el error clásico.

## En la herramienta

El recorrido vive entre el editor y GitHub. En el editor trabajas la rama y el `plan`; en GitHub
ves el Pull Request, los comentarios de revisión y el botón de merge. La idea es que **ningún
cambio llega a `main` sin pasar por un PR revisado**, igual que en un equipo real.

## Laboratorio

### Objetivo

Llevar un cambio (añadir una etiqueta común) desde una rama hasta `main` mediante un PR, pasando
por un conflicto y su resolución.

### En qué consiste

Creas una rama, modificas el código de `environments/dev`, abres un PR con la CLI de GitHub,
provocas y resuelves un conflicto, y mezclas.

### 1 — Crea una rama para tu cambio

**Acción:**

```bash
git switch -c feature/etiqueta-owner
```

**Por qué:** Aíslas tu cambio; `main` se mantiene estable mientras trabajas.
**Resultado esperado:** Estás en la rama `feature/etiqueta-owner` (`git status` lo confirma).

### 2 — Haz el cambio en el código

**Acción:** En `environments/dev/main.tf`, añade una etiqueta dentro de `locals`:

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "equipo-dev"
  }
}
```

**Por qué:** Es un cambio pequeño y revisable, típico de un PR real.
**Resultado esperado:** `terraform fmt` no se queja y el archivo queda con el bloque `common_tags`.

### 3 — Commitea y publica la rama

**Acción:**

```bash
git add environments/dev/main.tf
git commit -m "feat(dev): añade common_tags con Owner"
git push -u origin feature/etiqueta-owner
```

**Por qué:** Subes la rama para poder abrir el PR.
**Resultado esperado:** La rama existe en tu fork en GitHub.

### 4 — Abre el Pull Request

**Acción:**

```bash
gh pr create --base main --head feature/etiqueta-owner \
  --title "Añade common_tags en dev" \
  --body "Etiquetas comunes para el entorno dev."
```

**Por qué:** El PR es el punto de revisión antes de tocar `main`.
**Resultado esperado:** `gh` devuelve la URL del PR; puedes abrirla en el navegador.

> [!TIP]
> En un equipo, aquí otra persona revisaría el `plan`. En el curso puedes auto-revisarte:
> lee el diff con `gh pr diff` antes de mezclar.

### 5 — Provoca un conflicto (simulación de trabajo concurrente)

**Acción:** Simula que `main` cambió la misma línea mientras tú trabajabas:

```bash
git switch main
# edita environments/dev/main.tf y cambia Owner = "plataforma" en common_tags
git commit -am "feat(dev): Owner = plataforma"
git switch feature/etiqueta-owner
git merge main
```

**Por qué:** Reproduces el conflicto típico: dos ramas tocan la misma línea.
**Resultado esperado:** Git marca un conflicto en `main.tf` (`<<<<<<<`, `=======`, `>>>>>>>`).

### 6 — Resuelve el conflicto y completa el merge

**Acción:** Edita el archivo dejando el valor acordado (p. ej. `Owner = "plataforma"`), elimina
los marcadores y termina:

```bash
git add environments/dev/main.tf
git commit -m "merge: resuelve conflicto en common_tags"
git push
```

**Por qué:** El conflicto de **código** se resuelve editando y confirmando.
**Resultado esperado:** El PR queda sin conflictos y se puede mezclar (`gh pr merge --squash`).

## Conclusiones

- Cada cambio de infraestructura entra por una **rama** y se revisa en un **PR**.
- Los conflictos de **código** se resuelven editando; los de **estado**, no (M07/M08).
- La revisión del `plan` antes del merge evita sorpresas en `main`.

## Comprueba tu entendimiento

**El PR existe**
Ejecuta `gh pr status`.
→ Aparece tu PR con la rama `feature/etiqueta-owner`.

**Conflicto resuelto**
Tras resolverlo, ejecuta `git status`.
→ No quedan archivos en estado *unmerged* ni marcadores `<<<<<<<` en `main.tf`.

## Reto

### 1 — ¿Por qué no se mezcla el estado?

Si dos compañeros hacen `apply` a la vez con estado local, ¿qué problema aparece y cómo lo
resolverías?

<details>
<summary>Ver solución</summary>

Cada uno tendría su propio `.tfstate` y pisarían la realidad mutuamente (o lo corromperían). La
solución no es Git: es **estado remoto con bloqueo** (Terraform Cloud, M08), que impide que dos
`apply` corran a la vez sobre el mismo estado.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `gh: command not found` | No estás en el dev container o falta auth | Usa el dev container; `gh auth login` si hiciera falta |
| El push pide credenciales | El remoto no es tu fork | Comprueba `git remote -v`; debe apuntar a `tu-usuario/...` |
| El conflicto reaparece tras commitear | Quedaron marcadores `<<<<<<<` sin borrar | Edita el archivo, elimina los marcadores y vuelve a `git add` |
| Mezclaste sin revisar el `plan` | Falta el paso de revisión | Usa `gh pr diff` y, en módulos AWS, revisa el `terraform plan` antes del merge |
