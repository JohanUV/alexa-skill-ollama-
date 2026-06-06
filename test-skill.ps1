# Script para probar el skill localmente sin Alexa
param(
    [string]$Pregunta = "cuál es la capital de Ecuador"
)

Write-Host "=== Test del Alexa Skill IA ===" -ForegroundColor Cyan

# Test 1: LaunchRequest
Write-Host "`n[Test 1] LaunchRequest..." -ForegroundColor Yellow
$launchEvent = @{
    request = @{ type = "LaunchRequest" }
} | ConvertTo-Json -Compress

aws --endpoint-url=http://localhost:4566 lambda invoke `
    --function-name alexa-skill-ia `
    --payload $launchEvent `
    --cli-binary-format raw-in-base64-out `
    response.json 2>$null

if (Test-Path response.json) {
    $result = Get-Content response.json | ConvertFrom-Json
    Write-Host "Alexa dice: $($result.response.outputSpeech.text)" -ForegroundColor Green
    Remove-Item response.json
}

# Test 2: AskAIIntent
Write-Host "`n[Test 2] AskAIIntent: '$Pregunta'..." -ForegroundColor Yellow
$askEvent = @{
    request = @{
        type   = "IntentRequest"
        intent = @{
            name  = "AskAIIntent"
            slots = @{
                query = @{ value = $Pregunta }
            }
        }
    }
} | ConvertTo-Json -Depth 5 -Compress

aws --endpoint-url=http://localhost:4566 lambda invoke `
    --function-name alexa-skill-ia `
    --payload $askEvent `
    --cli-binary-format raw-in-base64-out `
    response.json 2>$null

if (Test-Path response.json) {
    $result = Get-Content response.json | ConvertFrom-Json
    Write-Host "Alexa dice: $($result.response.outputSpeech.text)" -ForegroundColor Green
    Remove-Item response.json
}

# Test 3: StopIntent
Write-Host "`n[Test 3] StopIntent..." -ForegroundColor Yellow
$stopEvent = @{
    request = @{
        type   = "IntentRequest"
        intent = @{ name = "AMAZON.StopIntent" }
    }
} | ConvertTo-Json -Depth 3 -Compress

aws --endpoint-url=http://localhost:4566 lambda invoke `
    --function-name alexa-skill-ia `
    --payload $stopEvent `
    --cli-binary-format raw-in-base64-out `
    response.json 2>$null

if (Test-Path response.json) {
    $result = Get-Content response.json | ConvertFrom-Json
    Write-Host "Alexa dice: $($result.response.outputSpeech.text)" -ForegroundColor Green
    Remove-Item response.json
}

Write-Host "`n=== Tests completados ===" -ForegroundColor Cyan
