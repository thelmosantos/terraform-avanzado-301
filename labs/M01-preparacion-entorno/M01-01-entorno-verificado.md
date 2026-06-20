# M01-01 — Entorno verificado

[← Página anterior](README.md) · [Siguiente página →](../M02-organizacion-proyectos/README.md)

En este primer laboratorio dejas tu entorno listo para todo el curso. El **dev container** ya
trae el tooling (Terraform, AWS CLI, Ansible, tflint); tu trabajo es **abrirlo**, **darle tus
credenciales** —aprenderás varias formas— y **verificar** que tienes los permisos necesarios.

### Objetivos

- Crear tu **fork** y abrir el proyecto dentro del **dev container** (Codespaces o local).
- Conocer las **distintas vías** para inyectar credenciales de AWS y elegir la tuya.
- **Verificar** identidad, herramientas y **permisos** con el tester del curso.

---

## Conceptos

El curso separa dos cosas a propósito:

- **El tooling viene resuelto.** El dev container (definido en `.devcontainer/`) construye una
  imagen con Terraform, AWS CLI v2, Ansible y tflint. No instalas nada a mano.
- **Las credenciales las pones tú.** Y hay varias formas de hacerlo. Saber elegir es parte del
  oficio, así que aquí las verás todas en vez de dártelas hechas:

| Vía | Cuándo | Cómo |
|-----|--------|------|
| **Codespaces secrets** | Trabajas en Codespaces | Settings → Codespaces → Secrets. Llegan como variables de entorno. |
| **`.env` local + direnv** | Trabajas en local con Docker | `cp .env.example .env`, lo editas y `direnv allow`. |
| **Asunción de rol** *(opcional)* | Te dan un rol que asumir | Defines `AWS_ROLE_ARN`; el setup crea un perfil `lab`. |

| Pieza | Para qué sirve |
|-------|----------------|
| **Fork** | Tu copia del repositorio base, que harás crecer durante el curso. |
| **Dev container** | Tu entorno reproducible (en la nube con Codespaces o en local con Docker). |
| **Terraform Cloud** | Estado remoto y colaboración (lo usarás a partir de M08). |

> [!NOTE]
> **Nunca** escribas tus claves dentro del código ni en archivos versionados. El `.env` está
> en `.gitignore` y en Codespaces las claves viven en *secrets*, fuera del repositorio.

## En la herramienta

### Apertura del entorno

Al abrir el proyecto en **Codespaces** (o en local con **Reopen in Container**), el dev
container se construye y, al terminar, ejecuta `setup-aws-profiles.sh`. Ese script imprime en la
terminal las herramientas detectadas, si hay credenciales activas y, si no las hay, te recuerda
las vías para ponerlas. Es tu panel de bienvenida: te dice exactamente qué falta.

## Laboratorio

### Objetivo

Terminar con el dev container abierto, credenciales activas y el **tester de permisos en verde**.

### En qué consiste

Forkeas, abres el entorno, eliges una vía de credenciales, verificas identidad y herramientas, y
lanzas el tester de permisos del curso.

### 1 — Haz un fork del repositorio base

**Acción:** En el repositorio base, pulsa **Fork** y confirma con **Create fork**.
**Por qué:** Necesitas tu propia copia para trabajar sin afectar al original.
**Resultado esperado:** La URL es `github.com/tu-usuario/terraform-avanzado-301`.

### 2 — Abre el dev container

**Acción:**
- En **Codespaces**: botón **Code → Codespaces → Create codespace on main**.
- En **local**: clona tu fork, ábrelo en VS Code y elige **Reopen in Container** (requiere Docker).

**Por qué:** Es tu entorno del curso, con todo el tooling ya instalado.
**Resultado esperado:** Se abre VS Code con una terminal; al final ves la salida de bienvenida del setup.

### 3 — Inyecta tus credenciales (elige una vía)

**Acción:** Según dónde trabajes:
- **Codespaces:** crea los *secrets* `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
  (y `AWS_SESSION_TOKEN` si son temporales) y `AWS_REGION`. Reabre el Codespace.
- **Local:** `cp .env.example .env`, edita tus claves y ejecuta `direnv allow`.

**Por qué:** El entorno trae los binarios, pero las credenciales son tuyas y deben quedar fuera del repo.
**Resultado esperado:** Las variables de AWS están disponibles en la terminal.

> [!TIP]
> En Codespaces, los *secrets* solo se cargan al **(re)crear** el Codespace. Si los añadiste
> después de abrirlo, reábrelo (Command Palette → *Rebuild Container*).

### 4 — Verifica identidad y herramientas

**Acción:**

```bash
aws sts get-caller-identity
terraform version
ansible --version
tflint --version
```

**Por qué:** Confirmas con qué identidad operas y que el tooling responde.
**Resultado esperado:** `get-caller-identity` devuelve tu `Account` y `Arn`; el resto imprime versiones.

> [!IMPORTANT]
> La cuenta AWS del curso solo está disponible **alrededor del horario de clase**. Si
> `get-caller-identity` falla fuera de ese horario, es lo esperado: reinténtalo en sesión.

### 5 — Comprueba los permisos con el tester del curso

**Acción:**

```bash
./scripts/check-aws-permissions.sh
```

**Por qué:** Antes de empezar, confirmas que tu cuenta puede hacer **todo** lo que pedirán los
labs (S3, IAM/STS, EC2/VPC), sin riesgo: los recursos de prueba se crean y se borran, y el
lanzamiento de EC2 se valida con `--dry-run` (no arranca nada).
**Resultado esperado:** Un resumen con `FAIL=0`. Si hay algún `FAIL`, compártelo con el formador.

### 6 — Inicia sesión en Terraform Cloud

**Acción:** `terraform login` y pega el token cuando se te pida.
**Por qué:** A partir de M08 guardarás el estado en Terraform Cloud; deja el acceso listo ya.
**Resultado esperado:** `Success! Terraform has obtained and saved an API token`.

## Conclusiones

- El dev container te da un entorno **idéntico** para todos, con el tooling resuelto.
- Hay **varias vías** de credenciales; sabes cuándo usar *secrets*, `.env` o asunción de rol.
- El **tester de permisos** te confirma que la cuenta es apta antes de empezar a construir.

## Comprueba tu entendimiento

**Identidad en AWS**
Ejecuta `aws sts get-caller-identity`.
→ Devuelve un JSON con tu `Account` y tu `Arn`.

**Permisos suficientes**
Ejecuta `./scripts/check-aws-permissions.sh`.
→ El resumen final muestra `FAIL=0`.

**Tooling disponible**
Ejecuta `terraform version` y `ansible --version`.
→ Ambos imprimen su versión sin errores.

## Reto

### 1 — ¿Qué vía de credenciales usarías en un pipeline?

Para tu portátil vale un `.env`; para Codespaces, los *secrets*. Pero, ¿qué usarías en un
pipeline de CI/CD para no dejar claves estáticas en ningún sitio?

<details>
<summary>Ver solución</summary>

**OIDC**: el pipeline asume un rol de AWS con un token efímero, sin almacenar claves. Lo montarás
en **M11 (Seguridad y gestión de secretos)**. Las claves estáticas son la última opción.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| `get-caller-identity` falla con error de credenciales | Fuera de la ventana AWS, o no cargaste credenciales | Verifica la hora; revisa *secrets*/`.env` y reabre el entorno |
| Las variables del `.env` no aparecen | No ejecutaste `direnv allow` | Lánzalo en la raíz del repo y reentra en la carpeta |
| Los *secrets* de Codespaces no se cargan | Los añadiste con el Codespace ya abierto | *Rebuild Container* o recrea el Codespace |
| `No region` / endpoint error | Falta `AWS_REGION` | Defínela (en *secrets* o en `.env`), p. ej. `eu-west-1` |
| `Reopen in Container` no aparece (local) | Docker no está corriendo o falta la extensión Dev Containers | Arranca Docker e instala la extensión *Dev Containers* |
| El tester muestra `FAIL` | La cuenta no tiene ese permiso | Copia el `FAIL` y pásalo al formador / área de sistemas |
