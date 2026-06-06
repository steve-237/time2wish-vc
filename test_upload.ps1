$loginResponse = Invoke-RestMethod -Uri 'http://localhost:8081/api/auth/login' -Method POST -Body '{"email":"test@example.com","password":"password123"}' -ContentType 'application/json'

$token = $loginResponse.accessToken
Write-Host "Got token: $token"

curl.exe -X POST http://localhost:8081/api/upload -H "Authorization: Bearer $token" -F "file=@dummy.png"
