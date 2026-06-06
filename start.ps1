param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey
)

Write-Host "=== Alexa Skill IA - Inicio ===" -ForegroundColor Cyan

$env:OPENAI_API_KEY = $ApiKey

Write-Host "`n[1/2] Iniciando servidor..." -ForegroundColor Yellow
Start-Process python -ArgumentList "server.py" -WindowStyle Normal

Start-Sleep -Seconds 2

Write-Host "[2/2] Iniciando ngrok..." -ForegroundColor Yellow
Start-Process ngrok -ArgumentList "http 5000" -WindowStyle Normal

Start-Sleep -Seconds 3

try {
    $tunnels = Invoke-WebRequest -Uri "http://localhost:4040/api/tunnels" -UseBasicParsing -ErrorAction Stop
    $url = ($tunnels.Content | ConvertFrom-Json).tunnels[0].public_url
    Write-Host "`n=== Listo! ===" -ForegroundColor Green
    Write-Host "URL del endpoint: $url" -ForegroundColor Cyan
    Write-Host "`nPega esta URL en la consola de Alexa (Endpoint > HTTPS > Default Region)"
    Write-Host "Luego di: 'Alexa, abre inteligencia artificial'"
} catch {
    Write-Host "No se pudo obtener la URL de ngrok" -ForegroundColor Red
}
