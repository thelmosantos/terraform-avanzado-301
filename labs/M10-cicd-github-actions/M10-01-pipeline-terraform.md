# M10-01 — Pipeline de Terraform

[← Página anterior](README.md) · [Siguiente página →](../M11-seguridad-secretos/README.md)

Aplicar infraestructura "a mano" desde tu portátil no escala ni es auditable. Un pipeline ejecuta
siempre los mismos pasos: valida y muestra el `plan` en cada PR, y solo aplica tras aprobación al
mezclar. En este laboratorio montas ese flujo con GitHub Actions.

> [!IMPORTANT]
> El `apply` del pipeline crea recursos en AWS. Trabaja en sesión y destruye al terminar.
> En este lab usamos secretos de repositorio; en **M11** los sustituiremos por **OIDC**.

### Objetivos

- Crear un workflow que haga `fmt`/`validate`/`plan` en cada Pull Request.
- Aplicar (`apply`) solo en el merge a `main`, con **aprobación** mediante *environment*.
- Pasar credenciales como **secretos**, nunca en el código.

---

## Conceptos

| Pieza | Rol |
|-------|-----|
| **Workflow** (`.github/workflows/*.yml`) | Define los pasos automáticos |
| **Trigger** (`on:`) | Cuándo corre: `pull_request` para validar, `push` a `main` para aplicar |
| **GitHub Secrets** | Credenciales inyectadas como variables, fuera del código |
| **Environment + required reviewers** | Puerta de **aprobación** antes del `apply` |

> [!IMPORTANT]
> **Plan en la PR, apply en el merge.** El `plan` se revisa antes de mezclar; el `apply` ocurre
> solo cuando el cambio entra en `main` y alguien lo aprueba.

## En la herramienta

El recorrido vive en la pestaña **Actions** de GitHub: verás el workflow corriendo en la PR
(con el `plan` en los logs) y, al mezclar, el job de `apply` esperando **aprobación** en el
*environment* `production` antes de ejecutarse.

## Laboratorio

### Objetivo

Crear `.github/workflows/terraform.yml` con validación en PR y apply aprobado en el merge.

### En qué consiste

Defines el workflow, configuras secretos y un environment con revisores, y compruebas el flujo.

### 1 — Crea el workflow

**Acción:** Crea `.github/workflows/terraform.yml`:

```yaml
name: terraform
on:
  pull_request:
    paths: ["environments/**", "modules/**"]
  push:
    branches: ["main"]

env:
  AWS_REGION: eu-west-1
  TF_WORKING_DIR: environments/dev

jobs:
  validate:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ env.TF_WORKING_DIR }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform fmt -check
      - run: terraform init -backend=false
      - run: terraform validate
```

**Por qué:** Toda PR queda validada automáticamente antes de mezclar.
**Resultado esperado:** El job `validate` corre en cada PR que toque infraestructura.

### 2 — Añade el plan en la PR

**Acción:** Añade un job que ejecute `terraform plan` usando credenciales:

```yaml
  plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ env.TF_WORKING_DIR }}
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform plan -no-color
```

**Por qué:** Quien revisa la PR ve exactamente qué cambiaría.
**Resultado esperado:** El `plan` aparece en los logs del check de la PR.

### 3 — Configura los secretos

**Acción:** En tu repo → *Settings → Secrets and variables → Actions*, crea
`AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`.
**Por qué:** Las credenciales no pueden estar en el código.
**Resultado esperado:** Los secretos existen y el job `plan` los usa.

### 4 — Apply con aprobación en el merge

**Acción:** Crea un *environment* `production` (*Settings → Environments*) con **required
reviewers** y añade el job:

```yaml
  apply:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production
    defaults:
      run:
        working-directory: ${{ env.TF_WORKING_DIR }}
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform apply -auto-approve
```

**Por qué:** El `apply` solo corre tras aprobación humana, al entrar en `main`.
**Resultado esperado:** Al mezclar, el job `apply` queda **esperando aprobación** en el environment.

### 5 — Prueba el flujo y limpia

**Acción:** Abre una PR (verás `validate` + `plan`), mézclala (el `apply` pedirá aprobación),
aprueba y, al terminar, destruye los recursos.
**Resultado esperado:** Flujo completo PR → plan → aprobación → apply, y recursos destruidos.

## Conclusiones

- El pipeline valida y planifica en cada PR y aplica solo tras aprobación.
- Las credenciales viven en **secretos**, nunca en el repo.
- El *environment* con revisores es la puerta de control antes de tocar infraestructura.

## Comprueba tu entendimiento

**Validación automática**
Abre una PR que toque `environments/`.
→ El check de `validate`/`plan` corre y muestra el plan.

**Aprobación antes del apply**
Mezcla la PR a `main`.
→ El job `apply` queda en espera hasta que un revisor lo aprueba.

## Reto

### 1 — Quitar las credenciales estáticas

Tener `AWS_ACCESS_KEY_ID` como secreto sigue siendo una clave de larga vida. ¿Cómo lo eliminarías
del todo?

<details>
<summary>Ver solución</summary>

Con **OIDC** (M11): el workflow asume un rol de AWS con un token efímero usando
`aws-actions/configure-aws-credentials` y `role-to-assume`, sin almacenar claves. Es el siguiente
módulo.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `terraform fmt -check` falla el job | Código sin formatear | Ejecuta `terraform fmt` y commitea |
| El `plan` falla por credenciales | Faltan los secretos o el job no los expone | Crea los secretos y mapéalos en `env:` |
| El `apply` corre sin aprobación | El environment no tiene required reviewers | Configura revisores en el environment |
| El workflow no se dispara | Los `paths` no coinciden | Ajusta `paths:` a tus carpetas reales |
