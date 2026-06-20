# M06-01 — Infraestructura dinámica

[← Página anterior](README.md) · [Siguiente página →](../M07-gestion-estado/README.md)

Repetir bloques casi idénticos es señal de que el código debería generarse solo. En este
laboratorio usas `for_each`, `count`, `locals` y condicionales para construir varios recursos a
partir de datos. Todo se valida con `plan`, sin aplicar: no consume AWS, así que puedes practicar
cuando quieras.

### Objetivos

- Generar N recursos a partir de un **mapa** con `for_each`.
- Entender la diferencia entre `for_each` y `count`.
- Usar `locals`, condicionales y funciones para parametrizar.

---

## Conceptos

| Mecanismo | Cuándo usarlo | Riesgo |
|-----------|---------------|--------|
| `for_each` | Conjunto de recursos con **clave estable** (mapa/set) | Bajo: cada recurso se identifica por su clave |
| `count` | On/off (`count = var.enabled ? 1 : 0`) o listas fijas | Al reordenar una lista, Terraform recrea recursos |

> [!IMPORTANT]
> **`for_each` por defecto.** Con `count` sobre una lista, si insertas un elemento al principio
> todos los índices se desplazan y Terraform recrea recursos que no cambiaron. Con `for_each`
> cada recurso se ancla a su clave y eso no pasa.

`locals` da nombre a valores calculados; los condicionales (`cond ? a : b`) y funciones (`merge`,
`lookup`, `toset`, `for`) construyen estructuras sin repetir.

## En la herramienta

En el editor defines un mapa de "buckets lógicos" y un solo bloque de recurso que `for_each`
expande. El `terraform plan` muestra un recurso por clave (`this["logs"]`, `this["data"]`…), no
una lista anónima: así se ve que la identidad es estable.

## Laboratorio

### Objetivo

Generar varios buckets a partir de un mapa con `for_each`, parametrizados con `locals` y un
condicional, y revisar el `plan`.

### En qué consiste

Defines datos en variables/locals y dejas que Terraform genere los recursos. No aplicas: te
quedas en `plan`.

### 1 — Define los datos con locals

**Acción:** En un directorio de prueba (p. ej. `labs-sandbox/m06/main.tf`):

```hcl
variable "project" {
  type    = string
  default = "tfadv"
}

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  prefix = "${var.project}-${var.environment}"

  buckets = {
    logs = { versioning = false }
    data = { versioning = true }
    tmp  = { versioning = false }
  }
}
```

**Por qué:** Los datos (qué buckets quieres) quedan separados de la lógica que los crea.
**Resultado esperado:** Un mapa `buckets` con tres entradas.

### 2 — Genera recursos con for_each

**Acción:**

```hcl
resource "aws_s3_bucket" "this" {
  for_each = local.buckets
  bucket   = "${local.prefix}-${each.key}"
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = { for k, v in local.buckets : k => v if v.versioning }
  bucket   = aws_s3_bucket.this[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}
```

**Por qué:** Un solo bloque crea N buckets; el segundo usa un `for` con condición para versionar
solo los que lo piden.
**Resultado esperado:** El `plan` propone 3 buckets y versionado solo en `data`.

### 3 — Añade un recurso condicional con count

**Acción:**

```hcl
variable "create_inventory" {
  type    = bool
  default = false
}

resource "aws_s3_bucket" "inventory" {
  count  = var.create_inventory ? 1 : 0
  bucket = "${local.prefix}-inventory"
}
```

**Por qué:** `count` con un booleano es el patrón correcto para "crear o no" un recurso.
**Resultado esperado:** Con el default `false`, el `plan` no incluye el bucket de inventario.

### 4 — Corrige la sintaxis y revisa el plan

**Acción:**

```bash
cd labs-sandbox/m06
terraform fmt
terraform init -backend=false
terraform plan
```

**Por qué:** Validas que las expresiones son correctas y ves qué se generaría.
**Resultado esperado:** `plan` lista `aws_s3_bucket.this["logs"|"data"|"tmp"]` y, al activar
`create_inventory=true`, aparece el bucket extra.

> [!TIP]
> Prueba `terraform plan -var "create_inventory=true"` para ver cómo el condicional añade el recurso.

## Conclusiones

- `for_each` genera recursos con **identidad estable** por clave; es la opción por defecto.
- `count` encaja en on/off y listas fijas, pero cuidado al reordenar.
- `locals`, condicionales y funciones (`for`, `merge`) eliminan la repetición.

## Comprueba tu entendimiento

**Generación por clave**
Ejecuta `terraform plan`.
→ Aparecen `aws_s3_bucket.this["logs"]`, `["data"]` y `["tmp"]`, y versionado solo en `data`.

**El condicional funciona**
Ejecuta `terraform plan -var "create_inventory=true"`.
→ El `plan` añade `aws_s3_bucket.inventory[0]`.

## Reto

### 1 — De lista a mapa

Te dan los nombres como **lista**: `["logs","data","tmp"]`. ¿Cómo los usarías con `for_each`
(que requiere mapa o set) sin sufrir el problema de los índices de `count`?

<details>
<summary>Ver solución</summary>

Conviértela en set con `toset(var.nombres)` y usa `for_each = toset(var.nombres)`, accediendo con
`each.value`. Así cada recurso se ancla a su valor, no a un índice posicional.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `Invalid for_each argument` | Pasaste una lista en vez de mapa/set | Usa `toset(...)` o un mapa |
| Recursos recreados al reordenar | Usaste `count` sobre una lista | Cambia a `for_each` con claves estables |
| `each.value is object` inesperado | Confundes `each.key` y `each.value` | `each.key` es la clave; `each.value` el valor |
| `plan` pide credenciales AWS | Hiciste `apply` en vez de `plan` | Quédate en `plan`; con `init -backend=false` basta para este lab |
