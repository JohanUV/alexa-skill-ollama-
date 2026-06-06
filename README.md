# Alexa Skill con Ollama

Skill de Alexa que usa un modelo de IA local (Ollama) como backend para responder preguntas. La infraestructura se despliega con Terraform sobre Floci (LocalStack) para testing local.

## Arquitectura

```
Usuario → Alexa → Lambda (Python) → Ollama (qwen3:1.7b) → Respuesta
                     ↑
              Floci (LocalStack)
```

## Requisitos

- Docker Desktop
- Terraform
- Ollama con modelo `qwen3:1.7b`

## Instalacion rapida

1. Instalar el modelo de Ollama:
```powershell
ollama pull qwen3:1.7b
```

2. Ejecutar el deploy:
```powershell
.\deploy.ps1
```

3. Probar el skill:
```powershell
.\test-skill.ps1
.\test-skill.ps1 -Pregunta "que es la computacion cuantica"
```

## Estructura

```
├── lambda/
│   └── lambda_function.py      # Handler del skill
├── terraform/
│   ├── main.tf                 # Provider AWS (Floci)
│   ├── lambda.tf               # Recurso Lambda
│   ├── variables.tf            # Variables (ollama_host, ollama_model)
│   └── outputs.tf              # ARN del Lambda
├── skill-model/
│   ├── interaction-model.json  # Intents y slots de Alexa
│   └── skill.json              # Manifiesto del skill
├── docker-compose.yml          # Floci (LocalStack)
├── deploy.ps1                  # Script de despliegue
└── test-skill.ps1              # Script de pruebas
```

## Intents disponibles

| Intent | Ejemplo |
|---|---|
| LaunchRequest | "Alexa, abre inteligencia artificial" |
| AskAIIntent | "preguntale que es la gravedad" |
| AMAZON.HelpIntent | "ayuda" |
| AMAZON.StopIntent | "para" |
