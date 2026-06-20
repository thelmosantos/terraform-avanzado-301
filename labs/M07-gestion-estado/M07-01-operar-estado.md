# M07-01 — Operar el estado

[← Página anterior](README.md) · [Siguiente página →](../M08-terraform-cloud/README.md)

El estado (`.tfstate`) es la memoria de Terraform: la correspondencia entre tu código y los
recursos reales. Operarlo bien te permite renombrar, reorganizar y diagnosticar sin destruir nada.
En este laboratorio creas un recurso mínimo y practicas las operaciones de estado y la detección
de drift.

> [!IMPORTANT]
> Este lab crea un bucket S3 real. Trabaja dentro de la ventana de clase y ejecuta
> `terraform destroy` al terminar.

### Objetivos

- Inspeccionar el estado con `state list` y `state show`.
- Renombrar un recurso en el estado con `state mv` (sin recrearlo).
- Detectar **drift** provocado fuera de Terraform.

---

## Conceptos

El `terraform state` no se edita a mano: tiene comandos para operarlo de forma segura.

| Comando | Qué hace |
|---------|----------|
| `state list` | Lista los recursos que Terraform gestiona |
| `state show <addr>` | Muestra los atributos de un recurso en el estado |
| `state mv <a> <b>` | Cambia la **dirección** de un recurso (renombrar/refactor) sin recrearlo |
| `state rm <addr>` | Deja de gestionar un recurso (NO lo destruye en AWS) |

**Drift** = la realidad y el estado difieren porque alguien cambió algo **fuera** de Terraform
(p. ej. desde la consola AWS). `terraform plan` lo detecta y propone reconciliar.

> [!NOTE]
> `state rm` **olvida** (Terraform deja de gestionarlo, el recurso sigue en AWS). `destroy`
> **elimina** el recurso real. No los confundas.

## En la herramienta

Aquí entra la **consola de AWS**: provocarás el drift cambiando una etiqueta del bucket desde la
consola y verás cómo `terraform plan`, sin que tú toques el código, detecta la diferencia y
propone deshacerla. Es la forma visual de entender qué es el estado.

## Laboratorio

### Objetivo

Crear un bucket, operar su entrada en el estado y detectar un drift introducido desde la consola.

### En qué consiste

Aplicas un recurso mínimo, lo inspeccionas, lo renombras en el estado y provocas drift.

### 1 — Crea un recurso mínimo

**Acción:** En un directorio de trabajo:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" {}

resource "aws_s3_bucket" "logs" {
  bucket = "tfadv-state-${replace(timestamp(), ":", "")}"
  tags   = { Name = "demo-estado" }
}
```

Aplica:

```bash
terraform init && terraform apply
```

**Por qué:** Necesitas un recurso real cuyo estado puedas inspeccionar.
**Resultado esperado:** Se crea el bucket y aparece en el estado.

> [!TIP]
> Si prefieres un nombre fijo y único, usa `random_id` en vez de `timestamp()`.

### 2 — Inspecciona el estado

**Acción:**

```bash
terraform state list
terraform state show aws_s3_bucket.logs
```

**Por qué:** Ves qué gestiona Terraform y los atributos guardados.
**Resultado esperado:** `state list` muestra `aws_s3_bucket.logs`; `state show` lista sus atributos.

### 3 — Renombra el recurso en el estado

**Acción:** Cambia en el código `resource "aws_s3_bucket" "logs"` por `"app_logs"` y mueve el estado:

```bash
terraform state mv aws_s3_bucket.logs aws_s3_bucket.app_logs
terraform plan
```

**Por qué:** `state mv` actualiza la dirección sin recrear el recurso.
**Resultado esperado:** `plan` no propone crear/destruir nada (solo cambió el nombre lógico).

### 4 — Provoca drift desde la consola AWS

**Acción:** En la **consola de AWS**, edita una etiqueta del bucket (cambia `Name` a otro valor).
Luego:

```bash
terraform plan
```

**Por qué:** Reproduces un cambio hecho fuera de Terraform.
**Resultado esperado:** `plan` detecta la diferencia y propone devolver la etiqueta al valor del código.

### 5 — Limpia

**Acción:**

```bash
terraform destroy
```

**Por qué:** Cuidas la ventana de acceso y el coste.
**Resultado esperado:** El bucket se elimina y el estado queda vacío.

## Conclusiones

- El estado es la memoria de Terraform; se opera con comandos, nunca a mano.
- `state mv` renombra sin recrear; `state rm` olvida sin destruir.
- `plan` detecta **drift** y propone reconciliar realidad y código.

## Comprueba tu entendimiento

**Inspección del estado**
Ejecuta `terraform state list`.
→ Aparece el bucket gestionado.

**Renombrado sin recreación**
Tras `state mv` y editar el nombre lógico, ejecuta `terraform plan`.
→ No propone crear ni destruir recursos.

**Drift detectado**
Cambia una etiqueta en la consola AWS y ejecuta `terraform plan`.
→ El `plan` muestra la diferencia y propone corregirla.

## Reto

### 1 — Sacar un recurso de Terraform sin destruirlo

Te piden que un bucket deje de gestionarse con Terraform pero **siga existiendo** en AWS. ¿Qué
comando usas y qué NO debes usar?

<details>
<summary>Ver solución</summary>

Usa `terraform state rm aws_s3_bucket.app_logs`: Terraform lo olvida pero el bucket permanece en
AWS. **No** uses `destroy`, que lo eliminaría de verdad.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `plan` quiere recrear tras renombrar | Cambiaste el nombre en el código sin `state mv` | Ejecuta `state mv` (o usa un bloque `moved`, M09) |
| `BucketAlreadyExists` | Nombre de bucket no único | Usa sufijo único (`random_id`, cuenta, región) |
| `state rm` no liberó el recurso en AWS | Es lo esperado: `rm` solo deja de gestionarlo | Para eliminarlo usa `destroy` antes del `rm` |
| Acceso AWS falla | Fuera de la ventana | Reintenta en sesión |
