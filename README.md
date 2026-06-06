# Alexa Skill con IA

Skill de Alexa que usa IA para responder preguntas por voz. Soporta OpenAI (gpt-4o-mini) para respuestas rapidas o Ollama para IA 100% local.

## Arquitectura

```
Usuario → Alexa → ngrok (HTTPS) → server.py → OpenAI API (gpt-4o-mini) → Respuesta
```

Para testing local con Terraform + Ollama:
```
Lambda → Floci (LocalStack) → Ollama (qwen3)
```

## Requisitos

- [Python 3.10+](https://www.python.org/downloads/)
- [ngrok](https://ngrok.com/download) (cuenta gratuita)
- [Cuenta de desarrollador de Alexa](https://developer.amazon.com/alexa/console/ask)
- API Key de [OpenAI](https://platform.openai.com/api-keys)

Para testing local (opcional):
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [Ollama](https://ollama.com/download)

## Instalacion

### 1. Clonar el repositorio

```powershell
git clone https://github.com/JohanUV/alexa-skill-ollama-.git
cd alexa-skill-ollama-
```

### 2. Configurar ngrok

Crea una cuenta gratuita en [ngrok.com](https://ngrok.com), obten tu authtoken y configuralo:

```powershell
ngrok config add-authtoken TU_AUTH_TOKEN
```

### 3. Configurar el Skill en Alexa Developer Console

1. Ir a [developer.amazon.com/alexa/console/ask](https://developer.amazon.com/alexa/console/ask)
2. **Create Skill** → Nombre: `Asistente IA` → Idioma: `Spanish (Mexico)` → **Custom** → **Provision your own** → **Start from Scratch**
3. En **Interaction Model → JSON Editor**, pegar el contenido de `skill-model/interaction-model.json`
4. **Save** → **Build skill**
5. Ir a **Endpoint** → seleccionar **HTTPS**
6. En **Default Region**, pegar la URL de ngrok (se obtiene en el paso siguiente)
7. SSL Certificate: **"My development endpoint is a sub-domain of a domain that has a wildcard certificate from a certificate authority"**
8. **Save Endpoints**
9. Ir a **Test** → cambiar de "Off" a **"Development"**

## Uso

### Inicio rapido

```powershell
.\start.ps1 -ApiKey "tu-api-key-de-openai"
```

Esto inicia el servidor y ngrok automaticamente. Copia la URL que muestra y pegala en el endpoint de Alexa.

### Inicio manual

1. **Configurar la API key:**
```powershell
$env:OPENAI_API_KEY = "tu-api-key-de-openai"
```

2. **Iniciar el servidor:**
```powershell
python server.py
```

3. **Exponer con ngrok (en otra terminal):**
```powershell
ngrok http 5000
```

4. **Copiar la URL HTTPS** que ngrok genera (ej: `https://xxxx-xxxx.ngrok-free.dev`) y pegarla en el endpoint de Alexa

5. **Hablar con Alexa:**
```
"Alexa, abre inteligencia artificial"
"pregunta que es la gravedad"
"cuanto es dos mas dos"
"dime quien invento el telefono"
```

### Testing local con Floci (sin Alexa)

Requiere Docker, Terraform y Ollama instalados.

```powershell
ollama pull qwen3:0.6b
.\deploy.ps1
.\test-skill.ps1
.\test-skill.ps1 -Pregunta "que es la computacion cuantica"
```

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
├── server.py                       # Servidor para Alexa (OpenAI)
├── start.ps1                       # Script de inicio rapido
├── lambda/
│   └── lambda_function.py          # Handler Lambda (testing con Ollama)
├── terraform/
│   ├── main.tf                     # Provider AWS (Floci/LocalStack)
│   ├── lambda.tf                   # Recurso Lambda
│   ├── variables.tf                # Variables de configuracion
│   ├── outputs.tf                  # ARN del Lambda
│   └── terraform.tfvars.example    # Ejemplo de configuracion
├── skill-model/
│   ├── interaction-model.json      # Intents y slots de Alexa
│   └── skill.json                  # Manifiesto del skill
├── docker-compose.yml              # Floci (LocalStack) para testing
├── deploy.ps1                      # Script de despliegue local
└── test-skill.ps1                  # Script de pruebas
```

## Costos

| Servicio | Costo |
|---|---|
| OpenAI gpt-4o-mini | ~$0.15 por cada 1000 preguntas |
| ngrok | Gratis (plan free) |
| Alexa Developer | Gratis |
| Ollama (testing local) | Gratis |

## Notas importantes

- **Tu PC debe estar encendida** con `server.py` y `ngrok` corriendo para que el skill funcione
- **La URL de ngrok cambia** cada vez que lo reinicias (plan gratuito). Actualiza el endpoint en la consola de Alexa cuando cambie
- **No subas tu API key a git**. Usa la variable de entorno `OPENAI_API_KEY` o el script `start.ps1`
