# Alexa Skill con Ollama

Skill de Alexa que usa un modelo de IA local (Ollama) como backend para responder preguntas. Toda la IA corre en tu propia maquina, sin costos de API.

## Arquitectura

```
Usuario → Alexa → ngrok (HTTPS) → server.py → Ollama (qwen3:0.6b) → Respuesta
```

Para testing local con Terraform:
```
server.py / Lambda → Floci (LocalStack) → Ollama
```

## Requisitos

- [Python 3.10+](https://www.python.org/downloads/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [Ollama](https://ollama.com/download)
- [ngrok](https://ngrok.com/download) (cuenta gratuita)
- [Cuenta de desarrollador de Alexa](https://developer.amazon.com/alexa/console/ask)

## Instalacion

### 1. Clonar el repositorio

```powershell
git clone https://github.com/JohanUV/alexa-skill-ollama-.git
cd alexa-skill-ollama-
```

### 2. Instalar el modelo de Ollama

```powershell
ollama pull qwen3:0.6b
```

### 3. Configurar ngrok

Crea una cuenta gratuita en [ngrok.com](https://ngrok.com), obtén tu authtoken y configúralo:

```powershell
ngrok config add-authtoken TU_AUTH_TOKEN
```

## Uso

### Opcion A: Conectar con Alexa real (ngrok)

1. **Iniciar el servidor:**
```powershell
python server.py
```

2. **Exponer con ngrok (en otra terminal):**
```powershell
ngrok http 5000
```

3. **Copiar la URL HTTPS** que ngrok genera (ej: `https://xxxx-xxxx.ngrok-free.dev`)

4. **Configurar el skill en la consola de Alexa** (ver seccion abajo)

5. **Hablar con Alexa:**
```
"Alexa, abre inteligencia artificial"
"pregunta que es la gravedad"
"cuanto es dos mas dos"
"dime quien invento el telefono"
```

### Opcion B: Testing local con Floci (LocalStack)

1. **Deploy automatico:**
```powershell
.\deploy.ps1
```

2. **Ejecutar tests:**
```powershell
.\test-skill.ps1
.\test-skill.ps1 -Pregunta "que es la computacion cuantica"
```

3. **Test manual con curl:**
```bash
curl -s -X POST "http://localhost:4566/2015-03-31/functions/alexa-skill-ia/invocations" \
  -H "Content-Type: application/json" \
  -d '{"request":{"type":"IntentRequest","intent":{"name":"AskAIIntent","slots":{"query":{"value":"que es la IA"}}}}}'
```

## Configurar el Skill en Alexa Developer Console

1. Ir a [developer.amazon.com/alexa/console/ask](https://developer.amazon.com/alexa/console/ask)
2. **Create Skill** → Nombre: `Asistente IA` → Idioma: `Spanish (Mexico)` → **Custom** → **Provision your own** → **Start from Scratch**
3. En **Interaction Model → JSON Editor**, pegar el contenido de `skill-model/interaction-model.json`
4. **Save** → **Build skill**
5. Ir a **Endpoint** → seleccionar **HTTPS**
6. En **Default Region**, pegar la URL de ngrok (ej: `https://xxxx-xxxx.ngrok-free.dev`)
7. SSL Certificate: **"My development endpoint is a sub-domain of a domain that has a wildcard certificate from a certificate authority"**
8. **Save Endpoints**
9. Ir a **Test** → cambiar de "Off" a **"Development"**
10. Probar escribiendo: `abre inteligencia artificial`

## Frases de ejemplo

| Frase | Accion |
|---|---|
| "Alexa, abre inteligencia artificial" | Iniciar el skill |
| "pregunta que es la gravedad" | Preguntar a la IA |
| "dime quien fue Einstein" | Preguntar a la IA |
| "cuanto es dos mas dos" | Preguntar a la IA |
| "que es la computacion cuantica" | Preguntar a la IA |
| "oye como se dice hola en japones" | Preguntar a la IA |
| "ayuda" | Instrucciones de uso |
| "para" | Cerrar el skill |

## Estructura del proyecto

```
alexa-skill-ollama/
├── server.py                       # Servidor HTTPS para Alexa (produccion)
├── lambda/
│   └── lambda_function.py          # Handler Lambda (testing con Floci)
├── terraform/
│   ├── main.tf                     # Provider AWS (Floci/LocalStack)
│   ├── lambda.tf                   # Recurso Lambda
│   ├── variables.tf                # Variables (ollama_host, ollama_model)
│   ├── outputs.tf                  # ARN del Lambda
│   └── terraform.tfvars.example    # Ejemplo de configuracion
├── skill-model/
│   ├── interaction-model.json      # Intents y slots de Alexa
│   └── skill.json                  # Manifiesto del skill
├── docker-compose.yml              # Floci (LocalStack) para testing
├── deploy.ps1                      # Script de despliegue local
└── test-skill.ps1                  # Script de pruebas
```

## Notas importantes

- **Tu PC debe estar encendida** para que el skill funcione (Ollama corre localmente)
- **La URL de ngrok cambia** cada vez que lo reinicias (plan gratuito). Actualiza el endpoint en la consola de Alexa cuando cambie
- **Alexa tiene un timeout de ~8 segundos**. Preguntas muy complejas pueden no alcanzar a responder
- El modelo `qwen3:0.6b` es el mas rapido (~4-6s por respuesta). Si tienes GPU, puedes usar `qwen3:1.7b` para mejor calidad
