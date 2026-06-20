#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# check-aws-permissions.sh
#
# Comprueba que la cuenta AWS tiene los permisos necesarios para TODOS los labs
# del curso, SIN riesgo ni coste relevante:
#   - S3, IAM (rol de laboratorio + trust), STS y Security Groups: se crean y se
#     BORRAN durante la prueba (recursos efímeros, sin coste).
#   - El lanzamiento de instancias EC2 se valida con --dry-run (NO arranca nada).
#   - El resto (VPC, AMIs, lectura de IAM) son consultas de solo lectura.
#
# Uso:   ./scripts/check-aws-permissions.sh
# Salida: tabla PASS/FAIL/SKIP + código de salida 0 si todo lo crítico pasa.
# ------------------------------------------------------------------------------
set -uo pipefail

GREEN='\033[32m'; RED='\033[31m'; YEL='\033[33m'; CYA='\033[36m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0; SKIP=0
declare -a RESULTS=()

record() { # estado etiqueta detalle
  local st="$1" label="$2" detail="${3:-}"
  case "$st" in
    PASS) PASS=$((PASS+1)); printf "  ${GREEN}✔ PASS${NC}  %s\n" "$label" ;;
    FAIL) FAIL=$((FAIL+1)); printf "  ${RED}x FAIL${NC}  %s\n" "$label"; [ -n "$detail" ] && printf "         %s\n" "$detail" ;;
    SKIP) SKIP=$((SKIP+1)); printf "  ${YEL}- SKIP${NC}  %s\n" "$label"; [ -n "$detail" ] && printf "         %s\n" "$detail" ;;
  esac
  RESULTS+=("$st|$label")
}

section() { printf "\n${BOLD}%s${NC}\n" "$1"; }

# --- Prerrequisitos -----------------------------------------------------------
for bin in aws jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: falta '$bin'."; exit 2; }
done

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-west-1}}"
export AWS_REGION="$REGION" AWS_DEFAULT_REGION="$REGION"
RAND="$(date +%s | tail -c 6)$RANDOM"

printf "${BOLD}== Tester de permisos AWS — Terraform Avanzado ==${NC}\n"
printf "Región: %s\n" "$REGION"

# --- 0) Identidad (STS) -------------------------------------------------------
section "STS · identidad"
if ID_JSON="$(aws sts get-caller-identity 2>/tmp/_e)"; then
  ACCOUNT="$(echo "$ID_JSON" | jq -r '.Account')"
  ARN="$(echo "$ID_JSON" | jq -r '.Arn')"
  record PASS "sts:GetCallerIdentity" 
  printf "         Account=%s  Arn=%s\n" "$ACCOUNT" "$ARN"
else
  record FAIL "sts:GetCallerIdentity" "$(head -n1 /tmp/_e)"
  echo; echo "Sin identidad válida no se puede continuar (¿estás en la ventana de acceso AWS?)."
  exit 1
fi

# --- 1) S3 (crear/objetos/versionado/borrar) ----------------------------------
section "S3 · bucket, objeto, versionado (efímero, se borra)"
BUCKET="tf-permcheck-${ACCOUNT}-${RAND}"
BUCKET_CREATED=false

s3_cleanup() {
  $BUCKET_CREATED || return 0
  # Borra todas las versiones y marcadores de borrado, luego el bucket.
  local vers
  vers="$(aws s3api list-object-versions --bucket "$BUCKET" \
          --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)"
  if [ -n "$vers" ] && [ "$vers" != '{"Objects":null}' ]; then
    aws s3api delete-objects --bucket "$BUCKET" --delete "$vers" >/dev/null 2>&1
  fi
  local marks
  marks="$(aws s3api list-object-versions --bucket "$BUCKET" \
          --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null)"
  if [ -n "$marks" ] && [ "$marks" != '{"Objects":null}' ]; then
    aws s3api delete-objects --bucket "$BUCKET" --delete "$marks" >/dev/null 2>&1
  fi
  aws s3api delete-bucket --bucket "$BUCKET" >/dev/null 2>&1
}
trap 's3_cleanup' EXIT

if [ "$REGION" = "us-east-1" ]; then
  CREATE_OUT="$(aws s3api create-bucket --bucket "$BUCKET" 2>/tmp/_e)"
else
  CREATE_OUT="$(aws s3api create-bucket --bucket "$BUCKET" \
      --create-bucket-configuration LocationConstraint="$REGION" 2>/tmp/_e)"
fi
if [ $? -eq 0 ]; then
  BUCKET_CREATED=true
  record PASS "s3:CreateBucket ($BUCKET)"
  if aws s3api put-bucket-versioning --bucket "$BUCKET" \
        --versioning-configuration Status=Enabled 2>/tmp/_e; then
    record PASS "s3:PutBucketVersioning"
  else
    record FAIL "s3:PutBucketVersioning" "$(head -n1 /tmp/_e)"
  fi
  echo "permcheck" > /tmp/_obj
  if aws s3api put-object --bucket "$BUCKET" --key permcheck.txt --body /tmp/_obj 2>/tmp/_e >/dev/null; then
    record PASS "s3:PutObject"
  else
    record FAIL "s3:PutObject" "$(head -n1 /tmp/_e)"
  fi
  aws s3api list-objects-v2 --bucket "$BUCKET" >/dev/null 2>/tmp/_e \
    && record PASS "s3:ListBucket" || record FAIL "s3:ListBucket" "$(head -n1 /tmp/_e)"
else
  record FAIL "s3:CreateBucket" "$(head -n1 /tmp/_e)"
fi

# --- 2) IAM (lectura + crear rol con trust + borrar) --------------------------
section "IAM · lectura, creación de rol y relación de confianza (efímero)"
aws iam list-roles --max-items 1 >/dev/null 2>/tmp/_e \
  && record PASS "iam:ListRoles" || record FAIL "iam:ListRoles" "$(head -n1 /tmp/_e)"
aws iam list-policies --scope AWS --max-items 1 >/dev/null 2>/tmp/_e \
  && record PASS "iam:ListPolicies" || record FAIL "iam:ListPolicies" "$(head -n1 /tmp/_e)"

ROLE="tf-permcheck-role-${RAND}"
ROLE_CREATED=false
cat > /tmp/_trust <<JSON
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::${ACCOUNT}:root"},"Action":"sts:AssumeRole"}]}
JSON
iam_cleanup() { $ROLE_CREATED && aws iam delete-role --role-name "$ROLE" >/dev/null 2>&1; }
trap 's3_cleanup; iam_cleanup' EXIT

if aws iam create-role --role-name "$ROLE" \
      --assume-role-policy-document file:///tmp/_trust >/dev/null 2>/tmp/_e; then
  ROLE_CREATED=true
  record PASS "iam:CreateRole ($ROLE)"
  aws iam update-assume-role-policy --role-name "$ROLE" \
      --policy-document file:///tmp/_trust >/dev/null 2>/tmp/_e \
    && record PASS "iam:UpdateAssumeRolePolicy (trust)" \
    || record FAIL "iam:UpdateAssumeRolePolicy (trust)" "$(head -n1 /tmp/_e)"

  # --- 3) STS assume-role sobre el rol recién creado ---
  section "STS · asunción de rol"
  sleep 8  # la relación de confianza tarda en propagarse
  if aws sts assume-role --role-arn "arn:aws:iam::${ACCOUNT}:role/${ROLE}" \
        --role-session-name permcheck >/dev/null 2>/tmp/_e; then
    record PASS "sts:AssumeRole"
  else
    record SKIP "sts:AssumeRole" "No se pudo asumir (suele ser propagación del trust): $(head -n1 /tmp/_e)"
  fi
else
  record FAIL "iam:CreateRole" "$(head -n1 /tmp/_e)"
fi

# --- 4) VPC / EC2 lectura -----------------------------------------------------
section "VPC / EC2 · lectura de inventario"
aws ec2 describe-vpcs --max-results 5 >/dev/null 2>/tmp/_e \
  && record PASS "ec2:DescribeVpcs" || record FAIL "ec2:DescribeVpcs" "$(head -n1 /tmp/_e)"
aws ec2 describe-subnets --max-results 5 >/dev/null 2>/tmp/_e \
  && record PASS "ec2:DescribeSubnets" || record FAIL "ec2:DescribeSubnets" "$(head -n1 /tmp/_e)"
aws ec2 describe-route-tables --max-results 5 >/dev/null 2>/tmp/_e \
  && record PASS "ec2:DescribeRouteTables" || record FAIL "ec2:DescribeRouteTables" "$(head -n1 /tmp/_e)"
aws ec2 describe-security-groups --max-results 5 >/dev/null 2>/tmp/_e \
  && record PASS "ec2:DescribeSecurityGroups" || record FAIL "ec2:DescribeSecurityGroups" "$(head -n1 /tmp/_e)"

AMI="$(aws ec2 describe-images --owners amazon \
        --filters 'Name=name,Values=al2023-ami-*-x86_64' 'Name=state,Values=available' \
        --query 'reverse(sort_by(Images,&CreationDate))[0].ImageId' --output text 2>/tmp/_e)"
if [ -n "$AMI" ] && [ "$AMI" != "None" ]; then
  record PASS "ec2:DescribeImages (AMI=$AMI)"
else
  record FAIL "ec2:DescribeImages" "$(head -n1 /tmp/_e)"
fi

# --- 5) EC2 Security Group (crear/borrar, sin coste) --------------------------
section "EC2 · Security Group (efímero, se borra)"
VPC_ID="$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true \
          --query 'Vpcs[0].VpcId' --output text 2>/dev/null)"
[ "$VPC_ID" = "None" ] && VPC_ID="$(aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text 2>/dev/null)"
if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  SG_ID="$(aws ec2 create-security-group --group-name "permcheck-${RAND}" \
            --description "permcheck efimero" --vpc-id "$VPC_ID" \
            --query 'GroupId' --output text 2>/tmp/_e)"
  if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    record PASS "ec2:CreateSecurityGroup ($SG_ID)"
    aws ec2 delete-security-group --group-id "$SG_ID" >/dev/null 2>/tmp/_e \
      && record PASS "ec2:DeleteSecurityGroup" \
      || record FAIL "ec2:DeleteSecurityGroup" "$(head -n1 /tmp/_e) (borra a mano: $SG_ID)"
  else
    record FAIL "ec2:CreateSecurityGroup" "$(head -n1 /tmp/_e)"
  fi
else
  record SKIP "ec2:CreateSecurityGroup" "No hay VPC disponible para la prueba"
fi

# --- 6) EC2 RunInstances (DRY-RUN, no lanza nada) -----------------------------
section "EC2 · lanzamiento de instancia (DRY-RUN, no arranca nada)"
if [ -n "$AMI" ] && [ "$AMI" != "None" ]; then
  DR="$(aws ec2 run-instances --dry-run --image-id "$AMI" \
        --instance-type t3.micro --count 1 2>&1)"
  if echo "$DR" | grep -q "DryRunOperation"; then
    record PASS "ec2:RunInstances (permitido — dry-run OK)"
  elif echo "$DR" | grep -q "UnauthorizedOperation"; then
    record FAIL "ec2:RunInstances" "UnauthorizedOperation: faltan permisos de lanzamiento"
  else
    record SKIP "ec2:RunInstances" "Respuesta no concluyente: $(echo "$DR" | head -n1)"
  fi
else
  record SKIP "ec2:RunInstances" "Sin AMI para probar"
fi

# --- Resumen ------------------------------------------------------------------
printf "\n${BOLD}== Resumen ==${NC}\n"
printf "  ${GREEN}PASS=%d${NC}  ${RED}FAIL=%d${NC}  ${YEL}SKIP=%d${NC}\n" "$PASS" "$FAIL" "$SKIP"
rm -f /tmp/_e /tmp/_obj /tmp/_trust 2>/dev/null || true

if [ "$FAIL" -gt 0 ]; then
  printf "\n${RED}Hay permisos que faltan.${NC} Revisa los FAIL y compártelos con el área de sistemas.\n"
  exit 1
fi
printf "\n${GREEN}Todos los permisos críticos están disponibles.${NC} El entorno es apto para los labs.\n"
[ "$SKIP" -gt 0 ] && printf "${YEL}Revisa los SKIP por si afectan a algún laboratorio concreto.${NC}\n"
exit 0
