$body = @{
    model = "qwen"
    messages = @(@{ role = "user"; content = "Hello" })
    stream = $false
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/v1/chat/completions' -Method POST -ContentType 'application/json' -Body $body -TimeoutSec 60
Write-Output $response.Content
