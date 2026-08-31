$ErrorActionPreference = "Stop"
$tokenFile = Join-Path $env:USERPROFILE ".zenodo_token.dpapi"
if (-not (Test-Path -LiteralPath $tokenFile)) { throw "Token file not found: $tokenFile" }

$enc = [IO.File]::ReadAllText($tokenFile).Trim()
$sec = ConvertTo-SecureString -String $enc
$bstr = [IntPtr]::Zero
try {
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    $headers = @{ Authorization = "Bearer $token" }
    Invoke-RestMethod -Method Get -Uri "https://zenodo.org/api/deposit/depositions" -Headers $headers | Out-Null
    Write-Host "ZENODO_API_OK"
}
finally {
    if ($bstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    Remove-Variable token,sec,enc -ErrorAction SilentlyContinue
}
