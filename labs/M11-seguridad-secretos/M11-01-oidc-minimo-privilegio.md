# M11-01 — OIDC y mínimo privilegio

[← Página anterior](README.md) · [Siguiente página →](../M12-troubleshooting/README.md)

Guardar `AWS_ACCESS_KEY_ID` como secreto funciona, pero es una clave de larga vida: si se filtra,
da acceso permanente. Con **OIDC**, GitHub Actions asume un rol de AWS con un **token efímero** y
sin almacenar credenciales. En este laboratorio montas OIDC y acotas el rol al mínimo privilegio.

> [!IMPORTANT]
> Este lab crea recursos IAM en AWS. Trabaja en sesión y limpia al terminar.

### Objetivos

- Establecer la confianza **OIDC** entre GitHub y AWS.
- Crear un **rol** asumible solo por tu repo/rama.
- Quitar las credenciales estáticas del pipeline y aplicar **mínimo privilegio**.

---

## Conceptos

| Concepto | Idea |
|----------|------|
| **OIDC** | GitHub emite un token de identidad por run; AWS confía en ese emisor |
| **IAM OIDC provider** | Registra a GitHub (`token.actions.githubusercontent.com`) como emisor de confianza |
| **Trust policy** | Define **quién** puede asumir el rol (acota por `repo:owner/repo:ref`) |
| **Permission policy** | Define **qué** puede hacer el rol (mínimo privilegio) |

> [!IMPORTANT]
> Distingue **quién** (trust policy) de **qué** (permission policy). Una trust demasiado abierta
> deja que otros repos asuman tu rol; una permission demasiado amplia da más poder del necesario.

## En la herramienta

El recorrido pasa por la **consola IAM** de AWS (proveedor OIDC, rol y sus dos políticas) y por
**GitHub Actions**, donde el workflow ya no lleva claves: usa
`aws-actions/configure-aws-credentials` con `role-to-assume` y obtiene credenciales temporales.

## Laboratorio

### Objetivo

Crear el proveedor OIDC, un rol acotado a tu repo y un workflow que lo asume sin secretos AWS.

### En qué consiste

Defines el provider y el rol (con Terraform), ajustas el workflow a OIDC y verificas.

### 1 — Registra el proveedor OIDC de GitHub

**Acción:** Con Terraform:

```hcl
data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}
```

**Por qué:** AWS necesita reconocer a GitHub como emisor de identidades de confianza.
**Resultado esperado:** El proveedor OIDC existe en IAM.

> [!TIP]
> Las versiones recientes del provider AWS pueden gestionar el thumbprint automáticamente; revisa
> la documentación del recurso para tu versión.

### 2 — Crea el rol con una trust policy acotada

**Acción:**

```hcl
variable "github_repo" {
  type        = string
  description = "owner/repo, p. ej. tu-usuario/terraform-avanzado-301"
}

resource "aws_iam_role" "gha" {
  name = "tfadv-gha-oidc"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })
}
```

**Por qué:** Solo runs de **tu repo** en la rama **main** podrán asumir el rol.
**Resultado esperado:** El rol existe y su confianza está acotada por `sub`.

### 3 — Adjunta permisos mínimos

**Acción:** Adjunta una política con solo lo que tus labs necesitan (p. ej. S3 del proyecto), no
`AdministratorAccess`:

```hcl
resource "aws_iam_role_policy" "gha_s3" {
  name = "tfadv-s3-min"
  role = aws_iam_role.gha.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:PutObject", "s3:GetObject", "s3:ListBucket"]
      Resource = ["arn:aws:s3:::tfadv-*", "arn:aws:s3:::tfadv-*/*"]
    }]
  })
}

output "role_arn" { value = aws_iam_role.gha.arn }
```

**Por qué:** Mínimo privilegio: el rol solo puede hacer lo justo.
**Resultado esperado:** El rol tiene permisos acotados a los buckets `tfadv-*`.

### 4 — Cambia el workflow a OIDC (sin secretos AWS)

**Acción:** En el job que aplica, añade permisos OIDC y usa el rol:

```yaml
permissions:
  id-token: write
  contents: read
steps:
  - uses: actions/checkout@v4
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::<ACCOUNT>:role/tfadv-gha-oidc
      aws-region: eu-west-1
  - uses: hashicorp/setup-terraform@v3
  - run: terraform init && terraform apply -auto-approve
    working-directory: environments/dev
```

**Por qué:** El workflow obtiene credenciales **temporales** sin secretos almacenados.
**Resultado esperado:** El run asume el rol; ya no hay `AWS_ACCESS_KEY_ID` en el repo.

### 5 — Quita los secretos estáticos y limpia

**Acción:** Borra los secretos `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` del repo. Al terminar,
`terraform destroy` de lo creado.
**Resultado esperado:** Cero claves estáticas; recursos IAM eliminados.

## Conclusiones

- OIDC sustituye claves de larga vida por **tokens efímeros**.
- La **trust policy** controla quién asume (acota `repo:...:ref:...`); la **permission policy**, qué puede hacer.
- Mínimo privilegio: concede solo lo que los labs necesitan.

## Comprueba tu entendimiento

**Sin secretos AWS**
Revisa *Settings → Secrets* del repo.
→ No hay `AWS_ACCESS_KEY_ID` ni `AWS_SECRET_ACCESS_KEY`.

**El run asume el rol**
Lanza el workflow y mira los logs de `configure-aws-credentials`.
→ Indica que asumió el rol y `aws sts get-caller-identity` muestra `assumed-role/tfadv-gha-oidc`.

## Reto

### 1 — Permitir también las PR desde ramas

Quieres que el `plan` corra en PRs desde cualquier rama, pero el `apply` siga restringido a `main`.
¿Cómo ajustas el `sub`?

<details>
<summary>Ver solución</summary>

Usa dos roles o condiciones distintas: para el `plan`, un `sub` más amplio como
`repo:owner/repo:pull_request`; para el `apply`, mantén `repo:owner/repo:ref:refs/heads/main`. Así
acotas cada acción a su contexto.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | `sub` de la trust no coincide con el repo/rama | Ajusta el `StringLike` del `sub` |
| `Credentials could not be loaded` | Falta `permissions: id-token: write` | Añádelo al job |
| El rol puede demasiado | Política amplia (`*`) | Acota acciones y `Resource` al mínimo |
| `InvalidIdentityToken` | `aud` incorrecto | Debe ser `sts.amazonaws.com` |
