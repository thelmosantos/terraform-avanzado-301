# M13-01 — Terraform + Ansible sobre EC2

[← Página anterior](README.md) · [Siguiente página →](../M14-caso-integrador/README.md)

Terraform es excelente **provisionando** (crear servidores, redes, permisos), pero la
**configuración** de lo que corre dentro (instalar y arrancar servicios) es el terreno de Ansible.
En este laboratorio Terraform crea una EC2 de bajo coste y exporta sus datos; Ansible la configura
a partir de un inventario generado de esos outputs.

> [!IMPORTANT]
> Este lab crea una instancia EC2 real (usa un tipo de bajo coste, p. ej. `t3.micro`). Trabaja en
> sesión y ejecuta `terraform destroy` al terminar.

### Objetivos

- Provisionar una EC2 + Security Group con Terraform y exportar su IP como **output**.
- Generar un **inventario** de Ansible a partir de los outputs.
- Configurar el servidor (instalar un servicio) con un **playbook**.

---

## Conceptos

| Herramienta | Responsabilidad | Ejemplo |
|-------------|-----------------|---------|
| **Terraform** | Provisión (infraestructura) | Crear EC2, SG, red, IP |
| **Ansible** | Configuración (dentro del SO) | Instalar y arrancar Nginx |

La unión entre ambos son los **outputs**: Terraform expone la IP pública y Ansible la usa como
host de su inventario.

> [!IMPORTANT]
> **Frontera clara.** Evita configurar el servicio con `user_data` *y además* con Ansible: elige
> dónde vive cada cosa para no duplicar ni pisarte.

## En la herramienta

En la **consola de AWS** (EC2) verás la instancia y su Security Group creados por Terraform. En la
terminal, Ansible se conecta por SSH a la IP del output y aplica el playbook. La idea: TF crea, el
output conecta, Ansible configura.

## Laboratorio

### Objetivo

Crear una EC2 con Terraform, generar el inventario y configurar Nginx con Ansible.

### En qué consiste

Provisionas con Terraform, exportas la IP, generas el inventario y lanzas el playbook.

### 1 — Provisiona la EC2 con Terraform

**Acción:** Define una instancia mínima con su SG (SSH y HTTP) y exporta la IP:

```hcl
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "web" {
  name        = "tfadv-web"
  description = "SSH y HTTP para el lab"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  tags                   = { Name = "tfadv-web" }
}

output "public_ip" { value = aws_instance.web.public_ip }
```

```bash
terraform init && terraform apply
```

**Por qué:** Terraform se ocupa de la infraestructura; la IP es el puente hacia Ansible.
**Resultado esperado:** Una EC2 corriendo y el output `public_ip`.

> [!TIP]
> `var.key_name` es un par de claves EC2 existente para poder entrar por SSH. Restringe el SG a tu
> IP en vez de `0.0.0.0/0` si quieres más seguridad.

### 2 — Genera el inventario de Ansible desde el output

**Acción:**

```bash
IP=$(terraform output -raw public_ip)
cat > inventory.ini <<EOF
[web]
$IP ansible_user=ec2-user
EOF
```

**Por qué:** Ansible necesita saber a qué host conectarse; lo tomas del output de Terraform.
**Resultado esperado:** `inventory.ini` con la IP de la instancia.

### 3 — Escribe el playbook

**Acción:** Crea `playbook.yml`:

```yaml
- hosts: web
  become: true
  tasks:
    - name: Instalar Nginx
      ansible.builtin.package:
        name: nginx
        state: present
    - name: Arrancar y habilitar Nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
```

**Por qué:** La configuración del servicio vive en Ansible, no en Terraform.
**Resultado esperado:** Un playbook que instala y arranca Nginx.

### 4 — Configura el servidor con Ansible

**Acción:**

```bash
ansible-playbook -i inventory.ini playbook.yml
```

**Por qué:** Ansible se conecta por SSH y aplica la configuración.
**Resultado esperado:** Nginx instalado y arrancado; al abrir `http://IP` responde.

### 5 — Limpia

**Acción:** `terraform destroy`.
**Por qué:** Una EC2 viva consume ventana y coste.
**Resultado esperado:** Instancia y SG eliminados.

## Conclusiones

- Terraform **provisiona**; Ansible **configura**. Cada uno en su terreno.
- Los **outputs** de Terraform alimentan el inventario de Ansible.
- Define la frontera para no duplicar configuración.

## Comprueba tu entendimiento

**Output disponible**
Ejecuta `terraform output -raw public_ip`.
→ Devuelve la IP pública de la instancia.

**Servicio configurado**
Tras el playbook, abre `http://<public_ip>`.
→ Responde la página por defecto de Nginx.

## Reto

### 1 — Inventario dinámico

Generar `inventory.ini` a mano no escala. ¿Cómo lo automatizarías para varias instancias?

<details>
<summary>Ver solución</summary>

Usa el **plugin de inventario dinámico de AWS** (`amazon.aws.aws_ec2`), que descubre instancias por
etiquetas, o haz que Terraform escriba el inventario con un `local_file`/`templatefile` a partir de
los outputs. Así Ansible siempre ve el inventario real sin editarlo a mano.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| Ansible no conecta (timeout SSH) | SG sin puerto 22 o key incorrecta | Abre 22 en el SG y usa la key correcta (`ansible_user=ec2-user`) |
| `UNREACHABLE` por host key | Primera conexión SSH | `export ANSIBLE_HOST_KEY_CHECKING=False` para el lab |
| `nginx` no se instala en AL2023 | Repos/paquete distinto | Usa el nombre de paquete correcto o `amazon-linux-extras`/`dnf` |
| La EC2 sigue tras el lab | Olvidaste destruir | `terraform destroy` |
