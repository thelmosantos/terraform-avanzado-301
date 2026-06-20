# M08-01 — Migración a Terraform Cloud

[← Página anterior](README.md) · [Siguiente página →](../M09-importacion-refactorizacion/README.md)

Un estado en tu portátil no sirve para un equipo: nadie más lo ve y dos `apply` simultáneos lo
corrompen. Terraform Cloud (TFC) guarda el estado de forma remota, lo bloquea durante cada
operación y deja registro de los runs. En este laboratorio migras un estado local a TFC y
compruebas el bloqueo.

> [!IMPORTANT]
> Este lab aplica sobre AWS a través de TFC. Trabaja en sesión y ejecuta `destroy` al terminar.

### Objetivos

- Configurar el backend `cloud` y migrar el estado local a un **workspace** de TFC.
- Configurar las **credenciales AWS** como variables del workspace.
- Observar el **locking** durante un run.

---

## Conceptos

| Concepto | Idea |
|----------|------|
| **Backend remoto** | El estado vive en TFC, no en tu disco |
| **Workspace** | Un estado aislado (por entorno/proyecto) dentro de tu organización |
| **Locking** | Mientras alguien aplica, el estado queda bloqueado: nadie más aplica a la vez |
| **Run** | Cada `plan`/`apply` queda registrado y es auditable |

> [!NOTE]
> Las credenciales de AWS NO viajan en el código. En TFC se definen como **variables de entorno
> del workspace** (`AWS_ACCESS_KEY_ID`, etc.), marcadas como sensibles.

## En la herramienta

El recorrido pasa por **Terraform Cloud** (`app.terraform.io`): verás tu organización, el
workspace recién creado, las variables de entorno (sensibles) y, al lanzar un `apply`, el run con
su estado de **locked** mientras se ejecuta. Es la pieza de colaboración del curso.

## Laboratorio

### Objetivo

Migrar el estado de un recurso mínimo a un workspace de TFC y ver el run con bloqueo.

### En qué consiste

Añades el bloque `cloud`, reinicializas migrando el estado, configuras credenciales en el
workspace y aplicas desde TFC.

### 1 — Inicia sesión en Terraform Cloud

**Acción:** Si no lo hiciste en M01:

```bash
terraform login
```

**Por qué:** Necesitas el token para que la CLI hable con TFC.
**Resultado esperado:** Token guardado correctamente.

### 2 — Declara el backend cloud

**Acción:** En tu configuración añade el bloque `cloud` (usa tu organización):

```hcl
terraform {
  cloud {
    organization = "tu-organizacion"
    workspaces {
      name = "tfadv-dev"
    }
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
```

**Por qué:** Le dices a Terraform que el estado vive en ese workspace de TFC.
**Resultado esperado:** El workspace `tfadv-dev` se creará al inicializar.

### 3 — Migra el estado

**Acción:**

```bash
terraform init
```

Cuando pregunte si quieres copiar el estado existente al backend `cloud`, responde `yes`.

**Por qué:** Mueves el estado local al workspace remoto sin recrear recursos.
**Resultado esperado:** El estado queda en TFC; localmente ya no se gestiona el `.tfstate`.

### 4 — Configura las credenciales AWS en el workspace

**Acción:** En `app.terraform.io`, en el workspace `tfadv-dev` → *Variables*, añade variables de
entorno **sensibles**: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (y `AWS_SESSION_TOKEN` si son
temporales) y `AWS_REGION`.

**Por qué:** TFC ejecuta los runs en remoto; necesita las credenciales para hablar con AWS.
**Resultado esperado:** El workspace tiene las variables marcadas como sensibles.

### 5 — Aplica y observa el bloqueo

**Acción:**

```bash
terraform apply
```

**Por qué:** El run se ejecuta en TFC; mientras corre, el workspace queda bloqueado.
**Resultado esperado:** Ves el run en la UI de TFC y, durante el `apply`, el estado aparece como
**locked** (un segundo `apply` esperaría).

### 6 — Limpia

**Acción:** `terraform destroy` y, si quieres, elimina el workspace en TFC.
**Resultado esperado:** Recursos destruidos; estado remoto vacío.

## Conclusiones

- El estado remoto en TFC hace posible el trabajo en equipo.
- El **locking** evita que dos `apply` corran a la vez sobre el mismo estado.
- Las credenciales viven en variables **sensibles** del workspace, no en el código.

## Comprueba tu entendimiento

**Estado en remoto**
Tras `terraform init` con el bloque `cloud`, ejecuta `terraform state list`.
→ Devuelve los recursos desde el estado remoto (ya no hay `.tfstate` local).

**Run en TFC**
Abre el workspace en `app.terraform.io`.
→ Aparece el run del `apply` con su registro.

## Reto

### 1 — Mismo código, dos entornos

Quieres `dev` y `prod` con el mismo código pero estados separados en TFC. ¿Cómo lo organizas?

<details>
<summary>Ver solución</summary>

Un **workspace por entorno** (`tfadv-dev`, `tfadv-prod`), cada uno con sus variables. Puedes
parametrizar el nombre del workspace o usar workspaces separados; el código es el mismo y el
estado queda aislado por workspace.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `Error: Required token could not be found` | No hiciste `terraform login` | Ejecuta `terraform login` |
| El `apply` en TFC falla por credenciales | Faltan las variables AWS del workspace | Añádelas como variables de entorno sensibles |
| `organization not found` | Nombre de organización incorrecto | Usa el nombre exacto de tu org en TFC |
| El estado no migró | Respondiste `no` al copiar | Repite `terraform init` y acepta la migración |
