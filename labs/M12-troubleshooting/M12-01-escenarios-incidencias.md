# M12-01 — Escenarios de incidencia

[← Página anterior](README.md) · [Siguiente página →](../M13-terraform-ansible/README.md)

Tarde o temprano algo falla: una variable mal, una dependencia imposible, un estado que no
coincide con la realidad. Saber diagnosticar con método vale más que memorizar errores. En este
laboratorio reproduces y resuelves varios escenarios típicos. La mayoría es local; alguno usa AWS.

### Objetivos

- Aplicar un **método** de diagnóstico: leer el error, reproducir, aislar, corregir.
- Usar `TF_LOG` para depurar el comportamiento del provider.
- Resolver dependencias circulares, variables incorrectas y drift.

---

## Conceptos

| Herramienta | Para qué |
|-------------|----------|
| Mensaje de error | Suele indicar archivo, línea y causa. **Léelo entero**, no solo la última frase. |
| `terraform validate` | Detecta errores de configuración antes de aplicar |
| `TF_LOG=DEBUG` / `TRACE` | Traza detallada del provider y las llamadas a la API |
| `terraform plan` | Revela drift y diferencias entre código y realidad |

> [!IMPORTANT]
> **Método > prueba y error.** Relanzar sin leer es la trampa. Lee el error, forma una hipótesis,
> reprodúcela en pequeño, corrige y verifica.

## En la herramienta

Trabajarás sobre todo en la terminal, leyendo errores y activando `TF_LOG`. Cuando un escenario
toque AWS (drift), la **consola** te sirve para ver el cambio que provocó la diferencia.

## Laboratorio

### Objetivo

Reproducir y resolver tres escenarios con método.

### En qué consiste

Cada escenario es un fallo provocado; tu trabajo es diagnosticar y corregir.

### 1 — Variable obligatoria sin valor

**Acción:** Declara una variable sin default y referénciala; ejecuta `terraform plan` sin pasarla:

```hcl
variable "bucket_name" { type = string }
```

```bash
terraform plan   # falla: no value for required variable
```

**Por qué:** Es el error de configuración más común.
**Resultado esperado:** Diagnosticas que falta el valor y lo aportas (`-var`, `tfvars` o default).

### 2 — Dependencia circular

**Acción:** Crea dos recursos que se referencien mutuamente (A usa un atributo de B y B uno de A) y
ejecuta `terraform plan`.
**Por qué:** Terraform no puede ordenar el grafo y lo dice explícitamente (`Cycle: ...`).
**Resultado esperado:** Identificas el ciclo y lo rompes (eliminando una referencia o introduciendo
un recurso intermedio / `depends_on` bien planteado).

### 3 — Depurar con TF_LOG

**Acción:**

```bash
TF_LOG=DEBUG terraform plan 2> debug.log
less debug.log
```

**Por qué:** Cuando el error del provider es opaco, la traza muestra las llamadas reales a la API.
**Resultado esperado:** Localizas en el log la operación que falla (permiso, parámetro, región).

### 4 — Drift (si tienes AWS en la ventana)

**Acción:** Con un recurso aplicado, cambia algo en la **consola AWS** y ejecuta `terraform plan`.
**Por qué:** Reproduces la diferencia realidad/estado.
**Resultado esperado:** `plan` muestra el drift; decides reconciliar (re-aplicar) o ajustar el código.

> [!TIP]
> Acuérdate de bajar el nivel de log (`unset TF_LOG`) al acabar: `TRACE`/`DEBUG` son muy verbosos.

## Conclusiones

- El error de Terraform casi siempre dice la verdad: léelo entero.
- `validate` atrapa errores pronto; `TF_LOG` destapa los del provider.
- Método: leer → reproducir → aislar → corregir → verificar.

## Comprueba tu entendimiento

**Variable resuelta**
Tras aportar el valor, ejecuta `terraform plan`.
→ Ya no se queja de la variable obligatoria.

**Ciclo roto**
Tras corregir la dependencia, ejecuta `terraform validate`.
→ No reporta `Cycle`.

## Reto

### 1 — Bloqueo de estado "fantasma"

Un `apply` se cortó y ahora todo dice `Error acquiring the state lock`. ¿Qué compruebas antes de
forzar nada?

<details>
<summary>Ver solución</summary>

Primero confirma que **no hay otra operación en curso** (otra persona/run). Si el lock quedó
huérfano, en Terraform Cloud puedes liberarlo desde la UI del workspace; con backend que lo
soporte, `terraform force-unlock <LOCK_ID>` como último recurso. Nunca fuerces si alguien podría
estar aplicando.

</details>

## Errores frecuentes

| Síntoma | Causa probable | Cómo arreglarlo |
|---------|----------------|-----------------|
| Relanzas y vuelve a fallar igual | No leíste el error completo | Lee archivo/línea/causa; forma una hipótesis |
| `Cycle:` en el grafo | Dependencia circular | Rompe una referencia o reordena con un recurso intermedio |
| Logs ilegibles | `TF_LOG` muy alto y sin redirigir | Usa `TF_LOG=DEBUG ... 2> debug.log` y revisa el archivo |
| `plan` siempre muestra cambios | Drift o atributos calculados | Identifica el origen; reconcilia o ajusta el código |
