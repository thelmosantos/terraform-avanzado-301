# M13 — Terraform + Ansible

[← Página anterior](../M12-troubleshooting/M12-01-escenarios-incidencias.md) · [Siguiente página →](M13-01-terraform-ansible-ec2.md)

> [!NOTE]
> **Cómo funciona este módulo.** Conceptos → recorrido **en la herramienta** → **laboratorio**
> que haces tú → conclusiones, comprobación y reto.

## Qué aprenderás

- Separar **provisión** (Terraform) de **configuración** (Ansible).
- Usar **outputs** de Terraform para generar el **inventario** de Ansible.
- Desplegar servicios básicos sobre una instancia EC2 de bajo coste.

## Contexto

- Terraform pone los servidores; Ansible instala lo que corre dentro.
- La frontera importa: decide qué hace cada herramienta para no duplicar.

> [!IMPORTANT]
> Este módulo crea una EC2 (bajo coste). Hazlo en sesión y ejecuta `terraform destroy` al terminar.

## Tabla de ejercicios

| Lab | Título | Qué harás |
|-----|--------|-----------|
| M13-01 | [Provisión con Terraform y configuración con Ansible](M13-01-terraform-ansible-ec2.md) | Crear una EC2, generar inventario desde outputs y configurarla con Ansible |

→ Empieza por **[M13-01 — Terraform + Ansible sobre EC2](M13-01-terraform-ansible-ec2.md)**.
