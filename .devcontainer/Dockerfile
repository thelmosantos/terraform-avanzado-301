# ------------------------------------------------------------------------------
# DevContainer — Terraform Avanzado: DevOps e IaC
# Tooling: Terraform, AWS CLI v2, Ansible, tflint y utilidades de IaC.
# (Sin Kubernetes/Helm/Flux: este curso usa AWS como provider de referencia.)
# ------------------------------------------------------------------------------

FROM ubuntu:22.04

# -------------------------------
# Regional y shell
# -------------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV PATH="${PATH}:/home/vscode/.local/bin"

# -------------------------------
# Versiones configurables
# -------------------------------
ARG TERRAFORM_VERSION=1.11.4
ARG KUBECTL_INSTALL=false
ARG ANSIBLE_CORE_VERSION=2.16.5
ARG ANSIBLE_VERSION=9.4.0

# -------------------------------
# Paquetes base del sistema
# -------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip git jq gnupg software-properties-common \
      direnv bash-completion python3 python3-pip less tree sudo \
      iputils-ping dnsutils netcat-openbsd locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------
# AWS CLI v2 (multi-arch)
# -------------------------------
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
      URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"; \
    else \
      URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; \
    fi && \
    curl -fsSL "$URL" -o awscliv2.zip && \
    unzip -q awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws && \
    aws --version

# -------------------------------
# Terraform (multi-arch)
# -------------------------------
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then TF_ARCH=arm64; else TF_ARCH=amd64; fi && \
    curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" -o terraform.zip && \
    unzip -q terraform.zip -d /usr/local/bin && rm terraform.zip && \
    terraform version

# -------------------------------
# tflint (linter de Terraform)
# -------------------------------
RUN curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    tflint --version

# -------------------------------
# Ansible + librerías Python para AWS
# -------------------------------
RUN pip3 install --no-cache-dir --upgrade pip setuptools && \
    pip3 install --no-cache-dir \
      ansible-core==${ANSIBLE_CORE_VERSION} \
      ansible==${ANSIBLE_VERSION} \
      boto3 botocore jmespath \
      yamllint ansible-lint python-dotenv && \
    ansible --version

# -------------------------------
# Integración con direnv (carga .env local)
# -------------------------------
RUN echo 'eval "$(direnv hook bash)"' >> /etc/bash.bashrc

# -------------------------------
# Usuario vscode sin prompt de sudo
# -------------------------------
RUN groupadd -g 1000 vscode && \
    useradd -m -u 1000 -g vscode -s /bin/bash vscode && \
    echo 'vscode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode

# Autocompletado de terraform y aws para vscode
RUN printf '%s\n' \
      'complete -C /usr/local/bin/terraform terraform' \
      'complete -C /usr/local/bin/aws_completer aws' \
      'eval "$(direnv hook bash)"' \
      >> /home/vscode/.bashrc && \
    chown vscode:vscode /home/vscode/.bashrc

USER vscode
ENV HOME=/home/vscode
WORKDIR /workspace
CMD ["sleep", "infinity"]
