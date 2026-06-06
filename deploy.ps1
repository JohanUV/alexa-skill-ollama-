Write-Host "=== Alexa Skill IA - Deploy en Floci ===" -ForegroundColor Cyan

# 1. Levantar Floci
Write-Host "`n[1/4] Levantando Floci..." -ForegroundColor Yellow
docker compose up -d
if (-not $?) {
    Write-Host "Error levantando Floci. Asegurate de tener Docker corriendo." -ForegroundColor Red
    exit 1
}

# 2. Esperar a que Floci este listo
Write-Host "`n[2/4] Esperando a que Floci este listo..." -ForegroundColor Yellow
$maxRetries = 30
$retry = 0
do {
    Start-Sleep -Seconds 2
    $retry++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:4566/_localstack/health" -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "Floci esta listo!" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "  Esperando... ($retry/$maxRetries)"
    }
} while ($retry -lt $maxRetries)

if ($retry -ge $maxRetries) {
    Write-Host "Floci no respondio a tiempo." -ForegroundColor Red
    exit 1
}

# 3. Verificar que Ollama este corriendo
Write-Host "`n[3/4] Verificando Ollama..." -ForegroundColor Yellow
try {
    $ollamaResponse = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -ErrorAction Stop
    $models = ($ollamaResponse.Content | ConvertFrom-Json).models.name
    if ($models -contains "qwen3:1.7b") {
        Write-Host "Ollama con qwen3:1.7b disponible!" -ForegroundColor Green
    } else {
        Write-Host "Modelo qwen3:1.7b no encontrado. Descargando..." -ForegroundColor Yellow
        ollama pull qwen3:1.7b
    }
} catch {
    Write-Host "Ollama no esta corriendo en localhost:11434" -ForegroundColor Red
    Write-Host "Inicia Ollama antes de continuar." -ForegroundColor Red
    exit 1
}

# 4. Terraform init + apply
Write-Host "`n[4/4] Desplegando infraestructura con Terraform..." -ForegroundColor Yellow
Push-Location terraform

if (-not (Test-Path "terraform.tfvars")) {
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    Write-Host "Se creo terraform.tfvars desde el ejemplo." -ForegroundColor Yellow
}

terraform init
if (-not $?) { Pop-Location; exit 1 }

terraform apply -auto-approve
if (-not $?) { Pop-Location; exit 1 }

Pop-Location

# Verificar el Lambda
Write-Host "`nVerificando despliegue..." -ForegroundColor Yellow

$testPayload = '{"request":{"type":"LaunchRequest"}}'
try {
    $result = Invoke-WebRequest -Uri "http://localhost:4566/2015-03-31/functions/alexa-skill-ia/invocations" `
        -Method POST -Body $testPayload -ContentType "application/json" -UseBasicParsing -ErrorAction Stop
    $speech = ($result.Content | ConvertFrom-Json).response.outputSpeech.text
    Write-Host "`nLambda responde: $speech" -ForegroundColor Green
} catch {
    Write-Host "No se pudo invocar el Lambda" -ForegroundColor Red
}

Write-Host "`n=== Deploy completado ===" -ForegroundColor Cyan
Write-Host "Lambda: arn:aws:lambda:us-east-1:000000000000:function:alexa-skill-ia"
Write-Host "Floci:  http://localhost:4566"
Write-Host "Ollama: http://localhost:11434"
Write-Host "`nPara probar: .\test-skill.ps1"
