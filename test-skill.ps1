param(
    [string]$Pregunta = "cual es la capital de Ecuador"
)

$endpoint = "http://localhost:4566/2015-03-31/functions/alexa-skill-ia/invocations"

function Invoke-Lambda($payload) {
    try {
        $result = Invoke-WebRequest -Uri $endpoint -Method POST -Body $payload `
            -ContentType "application/json" -UseBasicParsing -ErrorAction Stop -TimeoutSec 120
        return ($result.Content | ConvertFrom-Json)
    } catch {
        Write-Host "  Error: $_" -ForegroundColor Red
        return $null
    }
}

Write-Host "=== Test del Alexa Skill IA ===" -ForegroundColor Cyan

# Test 1: LaunchRequest
Write-Host "`n[Test 1] LaunchRequest..." -ForegroundColor Yellow
$result = Invoke-Lambda '{"request":{"type":"LaunchRequest"}}'
if ($result) {
    Write-Host "  Alexa dice: $($result.response.outputSpeech.text)" -ForegroundColor Green
}

# Test 2: AskAIIntent
Write-Host "`n[Test 2] AskAIIntent: '$Pregunta'..." -ForegroundColor Yellow
$askPayload = @{
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
$result = Invoke-Lambda $askPayload
if ($result) {
    Write-Host "  Alexa dice: $($result.response.outputSpeech.text)" -ForegroundColor Green
}

# Test 3: HelpIntent
Write-Host "`n[Test 3] HelpIntent..." -ForegroundColor Yellow
$helpPayload = @{
    request = @{
        type   = "IntentRequest"
        intent = @{ name = "AMAZON.HelpIntent" }
    }
} | ConvertTo-Json -Depth 3 -Compress
$result = Invoke-Lambda $helpPayload
if ($result) {
    Write-Host "  Alexa dice: $($result.response.outputSpeech.text)" -ForegroundColor Green
}

# Test 4: StopIntent
Write-Host "`n[Test 4] StopIntent..." -ForegroundColor Yellow
$stopPayload = @{
    request = @{
        type   = "IntentRequest"
        intent = @{ name = "AMAZON.StopIntent" }
    }
} | ConvertTo-Json -Depth 3 -Compress
$result = Invoke-Lambda $stopPayload
if ($result) {
    Write-Host "  Alexa dice: $($result.response.outputSpeech.text)" -ForegroundColor Green
}

Write-Host "`n=== Tests completados ===" -ForegroundColor Cyan
