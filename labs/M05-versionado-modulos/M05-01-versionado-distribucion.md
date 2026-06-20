# M05-01 — Versionado y distribución

[← Página anterior](README.md) · [Siguiente página →](../M06-expresiones-avanzadas/README.md)

Un módulo útil acaba usándose en varios proyectos. A partir de ahí necesita **versiones**: sus
consumidores deben poder fijar exactamente qué código usan y actualizar cuando quieran, no cuando
tú toques `main`. En este laboratorio publicas un módulo, lo versionas con un tag y lo consumes
por referencia. Es trabajo de Git: no consume AWS.

### Objetivos

- Publicar un módulo en un repositorio Git.
- Versionarlo con **tags** siguiendo **Semantic Versioning**.
- Consumir el módulo por `ref` y actualizar la versión de forma controlada.

---

## Conceptos

**Semantic Versioning (SemVer):** `MAJOR.MINOR.PATCH`.

| Cambias… | Subes… | Ejemplo |
|----------|--------|---------|
| Algo incompatible (rompes la interfaz) | **MAJOR** | `1.4.2 → 2.0.0` |
| Funcionalidad compatible (nuevo input opcional) | **MINOR** | `1.4.2 → 1.5.0` |
| Arreglo sin cambiar la interfaz | **PATCH** | `1.4.2 → 1.4.3` |

El consumidor fija la versión en el `source` del módulo. Así, aunque tú publiques `v2.0.0`, su
infraestructura no cambia hasta que él decide actualizar.

> [!IMPORTANT]
> Consumir un módulo desde `main` (sin `ref`) es pedir una rotura sorpresa: cualquier commit
> tuyo afecta a quien lo use. **Pinea siempre una versión.**

## En la herramienta

En GitHub verás el módulo publicado con sus **tags** (`v1.0.0`, `v1.1.0`) en la sección de
*Releases/Tags*. En el editor, el bloque `module` apunta a una `ref` concreta; al cambiar la `ref`
y reinicializar, Terraform descarga esa versión exacta.

## Laboratorio

### Objetivo

Publicar el módulo S3 (de M04) en un repo, etiquetarlo `v1.0.0`, consumirlo por `ref`, publicar
`v1.1.0` y actualizar de forma controlada.

### En qué consiste

Versionas un módulo con tags y demuestras que el consumidor controla cuándo adopta cada versión.

### 1 — Publica el módulo y etiqueta v1.0.0

**Acción:** Con el módulo S3 en su repositorio (o subcarpeta de módulos versionada):

```bash
git tag v1.0.0
git push origin v1.0.0
```

**Por qué:** El tag congela un punto exacto del código como versión consumible.
**Resultado esperado:** El tag `v1.0.0` aparece en GitHub.

### 2 — Consume el módulo por referencia

**Acción:** En el entorno consumidor, apunta el `source` a la versión:

```hcl
module "bucket" {
  source      = "git::https://github.com/tu-usuario/terraform-modules.git//s3?ref=v1.0.0"
  bucket_name = "${var.project}-${var.environment}-data"
  tags        = { ManagedBy = "terraform" }
}
```

**Por qué:** Fijas la versión exacta; nadie te cambia el módulo bajo los pies.
**Resultado esperado:** `terraform init` descarga el módulo en `v1.0.0`.

> [!TIP]
> El doble slash `//s3` indica la **subcarpeta** del módulo dentro del repo; `?ref=` fija el tag.

### 3 — Publica una nueva versión (cambio compatible)

**Acción:** Añade un input opcional al módulo (p. ej. `force_destroy` con default `false`), commitea y:

```bash
git tag v1.1.0
git push origin v1.1.0
```

**Por qué:** Es funcionalidad nueva compatible → sube **MINOR**.
**Resultado esperado:** Conviven `v1.0.0` y `v1.1.0`.

### 4 — Actualiza el consumidor de forma controlada

**Acción:** Cambia la `ref` a `v1.1.0` y reinicializa:

```bash
terraform init -upgrade
terraform plan
```

**Por qué:** La actualización ocurre **cuando tú decides**, no automáticamente.
**Resultado esperado:** `init -upgrade` trae `v1.1.0`; `plan` muestra solo lo que cambia.

## Conclusiones

- Un módulo versionado es un **producto**: el consumidor fija y actualiza versiones.
- **SemVer** comunica el impacto del cambio (MAJOR rompe, MINOR añade, PATCH arregla).
- Pinear `ref` evita roturas sorpresa; `init -upgrade` actualiza de forma explícita.

## Comprueba tu entendimiento

**La versión está fijada**
Mira el `source` del módulo en el consumidor.
→ Incluye `?ref=v1.0.0` (o la versión vigente), no `main`.

**Conviven versiones**
Ejecuta `git tag` en el repo del módulo.
→ Aparecen `v1.0.0` y `v1.1.0`.

## Reto

### 1 — Rango de versiones en el Terraform Registry

Si publicaras el módulo en el Terraform Registry en vez de Git, ¿cómo permitirías "cualquier 1.x
pero no 2.0"?

<details>
<summary>Ver solución</summary>

Con un módulo del Registry usas el argumento `version` y restricciones de versión:
`version = "~> 1.0"` (admite `>=1.0, <2.0`). Así recibes parches y minors compatibles, pero no el
MAJOR que podría romper. (Con `source` de Git se fija por `ref`, sin rangos.)

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `terraform init` no ve la nueva versión | El módulo quedó cacheado | Usa `terraform init -upgrade` |
| `Could not download module` | `ref` o subcarpeta `//` mal escritos | Revisa la URL, el `//subdir` y el `?ref=` |
| El consumidor cambió sin querer | Apuntabas a `main` | Pinea a un tag `?ref=vX.Y.Z` |
| Confusión MAJOR/MINOR | Cambio incompatible publicado como MINOR | Si rompes la interfaz, sube **MAJOR** |
