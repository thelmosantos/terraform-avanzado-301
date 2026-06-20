# M04-01 — Módulos de naming, tagging y S3

[← Página anterior](README.md) · [Siguiente página →](../M05-versionado-modulos/README.md)

Un módulo encapsula lógica para reutilizarla sin copiar y pegar. En este laboratorio creas tres
módulos pequeños —nomenclatura, etiquetado y un bucket S3 parametrizable— y los consumes desde
`environments/dev`. La mayor parte es diseño y validación local; el `apply` del bucket es opcional
y, si lo haces, recuerda destruirlo al terminar.

### Objetivos

- Crear módulos con **variables** (inputs) y **outputs**.
- Componer módulos entre sí (naming + tagging alimentan al de S3).
- Consumir los módulos desde un entorno y validar con `plan`.

---

## Conceptos

Un módulo es un directorio con archivos `.tf` que define **entradas** (`variable`), **lógica**
(recursos/`locals`) y **salidas** (`output`). Quien lo usa no necesita leer su interior: le pasa
inputs y recibe outputs.

| Pieza | Rol |
|-------|-----|
| `variable` | Input: lo que el módulo necesita saber |
| `output` | Lo que el módulo devuelve para que otros lo usen |
| `source` | Dónde vive el módulo (ruta local, Git, registry) |

> [!NOTE]
> **Empieza mínimo.** Un módulo con 20 inputs es difícil de usar. Expón solo lo que de verdad
> cambia entre usos; el resto, valores por defecto.

## En la herramienta

En el editor verás una carpeta `modules/` con un subdirectorio por módulo, y el entorno
`environments/dev` que los consume con bloques `module "..."`. El `terraform plan` muestra cómo
los outputs de un módulo (el prefijo de nombre, las etiquetas) alimentan al siguiente.

## Laboratorio

### Objetivo

Crear `modules/naming`, `modules/tagging` y `modules/s3`, y consumirlos desde `environments/dev`.

### En qué consiste

Defines tres módulos con sus inputs/outputs y los enlazas en el entorno. Validas con `plan`.

### 1 — Módulo de naming

**Acción:** Crea `modules/naming/main.tf`:

```hcl
variable "project"     { type = string }
variable "environment" { type = string }

output "prefix" {
  value = "${var.project}-${var.environment}"
}
```

**Por qué:** Centralizas la convención de nombres en un único sitio.
**Resultado esperado:** El módulo devuelve un `prefix` tipo `tfadv-dev`.

### 2 — Módulo de tagging

**Acción:** Crea `modules/tagging/main.tf`:

```hcl
variable "project"     { type = string }
variable "environment" { type = string }

variable "extra_tags" {
  type    = map(string)
  default = {}
}

output "tags" {
  value = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.extra_tags)
}
```

**Por qué:** Etiquetado consistente en todos los recursos, con extensión opcional.
**Resultado esperado:** Devuelve un mapa de etiquetas combinable.

### 3 — Módulo S3 parametrizable

**Acción:** Crea `modules/s3/main.tf`:

```hcl
variable "bucket_name" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "versioning" {
  type    = bool
  default = true
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

output "bucket_id"  { value = aws_s3_bucket.this.id }
output "bucket_arn" { value = aws_s3_bucket.this.arn }
```

**Por qué:** Encapsulas un bucket con versionado opcional, listo para reutilizar.
**Resultado esperado:** El módulo expone `bucket_id` y `bucket_arn`.

### 4 — Consume los módulos desde el entorno

**Acción:** En `environments/dev/main.tf`, añade:

```hcl
module "naming" {
  source      = "../../modules/naming"
  project     = var.project
  environment = var.environment
}

module "tags" {
  source      = "../../modules/tagging"
  project     = var.project
  environment = var.environment
}

module "bucket" {
  source      = "../../modules/s3"
  bucket_name = "${module.naming.prefix}-data-${var.aws_region}"
  tags        = module.tags.tags
}

output "bucket_id" { value = module.bucket.bucket_id }
```

**Por qué:** Demuestras la composición: un módulo alimenta al siguiente.
**Resultado esperado:** El bucket usará un nombre coherente con la convención.

### 5 — Inicializa y valida

**Acción:**

```bash
cd environments/dev
terraform init
terraform plan
```

**Por qué:** `init` descarga el provider y registra los módulos; `plan` muestra qué se crearía.
**Resultado esperado:** El `plan` propone crear el bucket con nombre y etiquetas correctos.

> [!WARNING]
> El `apply` de este lab crea un bucket real en AWS. Si lo aplicas, hazlo en sesión y al terminar
> ejecuta `terraform destroy`. Si solo quieres practicar el diseño, quédate en `plan`.

## Conclusiones

- Un módulo expone **inputs/outputs** y oculta su interior.
- Componer módulos (naming → tagging → s3) evita duplicar lógica.
- Mantén la interfaz **mínima**: solo lo que cambia entre usos.

## Comprueba tu entendimiento

**Los módulos se registran**
Ejecuta `terraform init` en `environments/dev`.
→ Aparecen los módulos `naming`, `tags` y `bucket` como inicializados.

**La composición funciona**
Ejecuta `terraform plan`.
→ El nombre del bucket incluye el prefijo `tfadv-dev` y lleva las etiquetas comunes.

## Reto

### 1 — Cifrado por defecto

¿Cómo añadirías cifrado en reposo al módulo S3 sin obligar a cada consumidor a configurarlo?

<details>
<summary>Ver solución</summary>

Añade dentro del módulo un `aws_s3_bucket_server_side_encryption_configuration` con SSE-S3
(`AES256`) por defecto, expuesto opcionalmente con una variable `encryption` (default `true`). El
consumidor obtiene cifrado sin tener que saber los detalles.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `Module not installed` | No ejecutaste `init` tras añadir módulos | Lanza `terraform init` |
| `BucketAlreadyExists` al aplicar | Los nombres de bucket son globales en AWS | Añade un sufijo único (región, cuenta o `random_id`) |
| `Unsupported argument` en un módulo | Pasas un input que el módulo no declara | Revisa las `variable` del módulo |
| El bucket queda tras la práctica | Olvidaste destruir | `terraform destroy` en `environments/dev` |
