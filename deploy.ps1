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

# 3. Terraform init + apply
Write-Host "`n[3/4] Desplegando infraestructura con Terraform..." -ForegroundColor Yellow
Push-Location terraform

if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "AVISO: No se encontro terraform.tfvars" -ForegroundColor Red
    Write-Host "Copia terraform.tfvars.example a terraform.tfvars y pon tu API key de Anthropic" -ForegroundColor Red
    Pop-Location
    exit 1
}

terraform init
if (-not $?) { Pop-Location; exit 1 }

terraform apply -auto-approve
if (-not $?) { Pop-Location; exit 1 }

Pop-Location

# 4. Verificar el Lambda
Write-Host "`n[4/4] Verificando despliegue..." -ForegroundColor Yellow

$testEvent = @{
    request = @{
        type = "LaunchRequest"
    }
} | ConvertTo-Json -Compress

aws --endpoint-url=http://localhost:4566 lambda invoke `
    --function-name alexa-skill-ia `
    --payload $testEvent `
    --cli-binary-format raw-in-base64-out `
    response.json 2>$null

if (Test-Path response.json) {
    Write-Host "`nRespuesta del Lambda:" -ForegroundColor Green
    Get-Content response.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
    Remove-Item response.json
} else {
    Write-Host "No se pudo invocar el Lambda" -ForegroundColor Red
}

Write-Host "`n=== Deploy completado ===" -ForegroundColor Cyan
Write-Host "Lambda ARN: arn:aws:lambda:us-east-1:000000000000:function:alexa-skill-ia"
Write-Host "Floci endpoint: http://localhost:4566"
Write-Host "`nPara probar manualmente:"
Write-Host '  aws --endpoint-url=http://localhost:4566 lambda invoke --function-name alexa-skill-ia --payload "{\"request\":{\"type\":\"LaunchRequest\"}}" out.json && cat out.json'
