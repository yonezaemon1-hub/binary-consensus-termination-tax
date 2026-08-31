$ErrorActionPreference = "Stop"
$tokenFile = Join-Path $env:USERPROFILE ".zenodo_token.dpapi"

Write-Host "A Windows credential dialog will open."
Write-Host "Paste the Zenodo personal access token into the Password field."
Write-Host "Required scopes: deposit:write, deposit:actions"

$cred = Get-Credential -UserName "zenodo-token" -Message "Paste Zenodo token into Password, then click OK"
$enc = ConvertFrom-SecureString -SecureString $cred.Password
[IO.File]::WriteAllText($tokenFile, $enc)

$bstr = [IntPtr]::Zero
try {
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Password)
    $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    if ($token.Length -lt 40) { throw "Token looks too short (length=$($token.Length))." }
    Write-Host "ZENODO_TOKEN_SAVED=$tokenFile"
    Write-Host "TOKEN_LENGTH=$($token.Length)"
}
finally {
    if ($bstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    Remove-Variable token,cred,enc -ErrorAction SilentlyContinue
}
