# M02-01 — Estructura multi-entorno

[← Página anterior](README.md) · [Siguiente página →](../M03-git-iac/README.md)

Un proyecto Terraform real se despliega en varios entornos (dev, test, prod) que comparten el
mismo código pero cambian sus valores. En este laboratorio montas esa estructura y la validas.
No creas infraestructura en AWS: es trabajo de organización y validación, así que puedes
repetirlo cuando quieras.

### Objetivos

- Montar un layout de repositorio preparado para **dev / test / prod**.
- Separar lo común (código) de lo que cambia por entorno (**variables**).
- Validar la estructura con `terraform fmt` y `terraform validate`.

---

## Conceptos

La idea central: **una sola receta (código), varias despensas (variables)**. El código que
describe la infraestructura es el mismo; lo que cambia por entorno son los valores (tamaños,
nombres, número de recursos), que viven en archivos `*.tfvars` separados.

| Archivo | Qué contiene |
|---------|--------------|
| `main.tf` | Los recursos y la lógica (igual en todos los entornos) |
| `variables.tf` | La **declaración** de las variables (qué se puede parametrizar) |
| `terraform.tfvars` | Los **valores** concretos de ese entorno |

> [!NOTE]
> **No confundas declarar con asignar.** `variables.tf` declara que existe una variable
> `environment`; `terraform.tfvars` le da el valor `"dev"`. Lo primero es la forma; lo segundo,
> el contenido.

Una convención de **nomenclatura** consistente (por ejemplo `proyecto-entorno-recurso`) evita
choques de nombres entre entornos y hace el inventario legible.

## En la herramienta

### Recorrido por la estructura

Al abrir el explorador de archivos del Codespace, la estructura del proyecto deja claro de un
vistazo qué es común y qué es por entorno: una carpeta `environments/` con una subcarpeta por
cada entorno, y cada una con su `terraform.tfvars`. El código compartido se reutiliza; los
valores viven junto a cada entorno:

```text
environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
├── test/
│   └── …
└── prod/
    └── …
```

## Laboratorio

### Objetivo

Crear una estructura `environments/{dev,test,prod}` con variables por entorno y dejarla
formateada y validada.

### En qué consiste

Creas las carpetas y archivos, declaras variables comunes, das valores distintos por entorno y
compruebas que todo está bien formado con `fmt` y `validate`.

### 1 — Crea la estructura de carpetas

**Acción:** En la terminal del Codespace, dentro de tu repo, crea las carpetas:

```bash
mkdir -p environments/dev environments/test environments/prod
```

**Por qué:** Cada entorno tendrá su configuración aislada, evitando mezclar valores de dev y prod.
**Resultado esperado:** Existen las tres carpetas bajo `environments/`.

### 2 — Declara las variables comunes

**Acción:** Crea `environments/dev/variables.tf` con:

```hcl
variable "project" {
  type        = string
  description = "Nombre corto del proyecto"
}

variable "environment" {
  type        = string
  description = "Entorno: dev, test o prod"
}

variable "aws_region" {
  type        = string
  description = "Región de AWS de referencia"
  default     = "eu-west-1"
}
```

**Por qué:** Defines qué se puede parametrizar, sin fijar todavía los valores.
**Resultado esperado:** El archivo declara tres variables sin errores de sintaxis.

### 3 — Da valores al entorno dev

**Acción:** Crea `environments/dev/terraform.tfvars`:

```hcl
project     = "tfadv"
environment = "dev"
aws_region  = "eu-west-1"
```

**Por qué:** Aquí viven los valores **concretos** de dev, separados del código.
**Resultado esperado:** El entorno dev tiene sus valores propios.

### 4 — Define un nombre consistente y un output

**Acción:** Crea `environments/dev/main.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "${var.project}-${var.environment}"
}

output "name_prefix" {
  value = local.name_prefix
}
```

**Por qué:** Demuestras la convención de nombres (`proyecto-entorno`) sin crear aún recursos.
**Resultado esperado:** `name_prefix` valdrá `tfadv-dev` en este entorno.

### 5 — Formatea y valida

**Acción:** Desde `environments/dev`, ejecuta:

```bash
cd environments/dev
terraform fmt
terraform init -backend=false
terraform validate
```

**Por qué:** `fmt` deja el estilo canónico; `init -backend=false` prepara el provider sin
necesitar credenciales; `validate` confirma que la configuración es coherente.
**Resultado esperado:** `terraform validate` responde `Success! The configuration is valid.`

### 6 — Replica en test y prod

**Acción:** Copia los archivos de `dev` a `test` y `prod`, y cambia en cada `terraform.tfvars`
el valor de `environment` (`test`, `prod`).
**Por qué:** Mismo código, distinta despensa: así se gestionan varios entornos sin duplicar lógica.
**Resultado esperado:** Cada entorno produce su propio `name_prefix` (`tfadv-test`, `tfadv-prod`).

## Conclusiones

- Una estructura multi-entorno separa **código común** de **valores por entorno**.
- `variables.tf` declara; `terraform.tfvars` asigna.
- Una **nomenclatura** consistente evita choques y hace legible el inventario.
- `fmt` + `validate` te dan confianza antes de aplicar nada.

## Comprueba tu entendimiento

**La configuración es válida**
Ejecuta `terraform validate` en `environments/dev`.
→ Responde `Success! The configuration is valid.`

**El prefijo cambia por entorno**
Compara el valor de `environment` en los `terraform.tfvars` de dev, test y prod.
→ Cada entorno produce un `name_prefix` distinto (`tfadv-dev`, `tfadv-test`, `tfadv-prod`).

## Reto

### 1 — Evitar repetir la región

Ahora `aws_region` está repetida en cada entorno. ¿Cómo evitarías duplicarla si los tres
entornos usan la misma región por defecto?

<details>
<summary>Ver solución</summary>

Da un `default` a `aws_region` en `variables.tf` y **no** la pongas en los `terraform.tfvars`
salvo en el entorno que necesite una región distinta. Así el valor por defecto se hereda y solo
se sobreescribe donde haga falta. (En M04 verás cómo encapsular esto en un módulo.)

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `terraform validate` pide credenciales o acceso a AWS | Hiciste `init` sin `-backend=false` o intentaste `plan`/`apply` | Para validar la estructura basta `init -backend=false` + `validate`; no necesitas AWS |
| `Error: Reference to undeclared input variable` | Usas una variable que no está en `variables.tf` | Declárala en `variables.tf` antes de usarla |
| `terraform fmt` cambia muchos archivos | El código no estaba en estilo canónico | Es normal; revisa el diff y confirma los cambios |
| Valores de un entorno aparecen en otro | Copiaste `terraform.tfvars` sin cambiar `environment` | Ajusta el valor de `environment` en cada carpeta |
