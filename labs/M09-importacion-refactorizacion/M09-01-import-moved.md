# M09-01 — Import y moved

[← Página anterior](README.md) · [Siguiente página →](../M10-cicd-github-actions/README.md)

En la vida real heredas infraestructura que no nació en Terraform, y reorganizas código sin querer
destruir nada. Las herramientas son `import` (adoptar lo existente) y `moved` (renombrar/refactor
sin recrear). En este laboratorio practicas ambas sobre un bucket S3.

> [!IMPORTANT]
> Este lab crea recursos reales en AWS. Trabaja en sesión y ejecuta `terraform destroy` al terminar.

### Objetivos

- **Importar** a Terraform un recurso creado por fuera.
- Refactorizar con un bloque **`moved`** sin recrear el recurso.
- Entender por qué primero va el **código** y luego el `import`.

---

## Conceptos

| Herramienta | Para qué | Clave |
|-------------|----------|-------|
| `terraform import` / bloque `import {}` | Adoptar un recurso que ya existe en el proveedor | **Primero** escribe el recurso en HCL, luego importa |
| Bloque `moved {}` | Renombrar/mover un recurso en el código sin recrearlo | Terraform actualiza la dirección, no destruye |

> [!IMPORTANT]
> Si renombras un recurso en el código sin `moved` (ni `state mv`), Terraform ve "uno que sobra y
> uno nuevo" y propone **destruir + crear**. `moved` se lo explica y evita el impacto.

## En la herramienta

Crearás un bucket "a mano" (consola AWS o `aws s3api`) para simular infraestructura preexistente,
y luego lo adoptarás desde Terraform. En la **consola de AWS** podrás ver que el bucket no cambia
al importarlo: Terraform solo empieza a gestionarlo.

## Laboratorio

### Objetivo

Adoptar un bucket existente con `import` y luego renombrarlo en el código con `moved`.

### En qué consiste

Creas el recurso fuera de Terraform, lo describes en HCL, lo importas y refactorizas con `moved`.

### 1 — Crea un bucket "por fuera"

**Acción:**

```bash
BUCKET="tfadv-import-$(aws sts get-caller-identity --query Account --output text)-$RANDOM"
aws s3api create-bucket --bucket "$BUCKET" \
  --create-bucket-configuration LocationConstraint="${AWS_REGION:-eu-west-1}"
echo "$BUCKET"
```

**Por qué:** Simulas infraestructura que ya existía antes de Terraform.
**Resultado esperado:** El bucket existe en AWS y conoces su nombre.

### 2 — Escribe el recurso en HCL (antes de importar)

**Acción:** En tu configuración:

```hcl
resource "aws_s3_bucket" "legacy" {
  bucket = "EL-NOMBRE-DEL-BUCKET-DEL-PASO-1"
}
```

**Por qué:** `import` necesita un recurso destino ya declarado en el código.
**Resultado esperado:** El recurso `aws_s3_bucket.legacy` existe en HCL (aún no en el estado).

### 3 — Importa el recurso

**Acción (opción CLI):**

```bash
terraform init
terraform import aws_s3_bucket.legacy "EL-NOMBRE-DEL-BUCKET"
```

**Acción (opción declarativa, Terraform ≥ 1.5):** añade un bloque `import` y haz `plan`/`apply`:

```hcl
import {
  to = aws_s3_bucket.legacy
  id = "EL-NOMBRE-DEL-BUCKET"
}
```

**Por qué:** Terraform empieza a gestionar el bucket existente sin recrearlo.
**Resultado esperado:** `terraform plan` ya no propone crear el bucket; está bajo gestión.

### 4 — Refactoriza con moved

**Acción:** Renombra el recurso en el código de `legacy` a `data` y añade:

```hcl
moved {
  from = aws_s3_bucket.legacy
  to   = aws_s3_bucket.data
}

resource "aws_s3_bucket" "data" {
  bucket = "EL-NOMBRE-DEL-BUCKET"
}
```

Luego:

```bash
terraform plan
```

**Por qué:** `moved` le dice a Terraform que es el mismo recurso con otro nombre lógico.
**Resultado esperado:** `plan` muestra el `moved` y **no** propone destruir/crear.

### 5 — Limpia

**Acción:** `terraform destroy` (o `aws s3api delete-bucket` si no llegaste a gestionarlo).
**Resultado esperado:** El bucket se elimina.

## Conclusiones

- `import` adopta recursos existentes; **primero el código, luego el import**.
- `moved` renombra/refactoriza sin destruir ni recrear.
- Así se evolucionan infraestructuras en producción sin impacto.

## Comprueba tu entendimiento

**Recurso adoptado**
Tras importar, ejecuta `terraform plan`.
→ No propone crear el bucket (ya está gestionado).

**Refactor sin impacto**
Tras añadir `moved` y renombrar, ejecuta `terraform plan`.
→ Muestra el movimiento y no propone destruir/crear.

## Reto

### 1 — Importar muchos recursos

Heredas 30 buckets creados a mano. ¿Qué enfoque usarías para no escribir 30 `import` a mano?

<details>
<summary>Ver solución</summary>

Combina **bloques `import`** (declarativos) generados a partir de un listado, o usa
`terraform plan -generate-config-out=...` (genera el HCL de los recursos importados) para no
escribir la configuración a mano. Luego revisas y ajustas el código generado.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `resource address does not exist` al importar | No declaraste el recurso en HCL antes | Escribe el `resource` y reintenta el `import` |
| `plan` propone destruir+crear tras renombrar | Falta el bloque `moved` | Añade `moved { from = ... to = ... }` |
| `BucketAlreadyOwnedByYou` | Reintentas crear uno que ya tienes | Importa el existente en vez de crearlo |
| Acceso AWS falla | Fuera de la ventana | Reintenta en sesión |
