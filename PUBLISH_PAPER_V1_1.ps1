param(
    [switch]$Publish
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$PaperDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $PaperDir "paper.publish.json"
$StatePath = Join-Path $PaperDir ".publish_state.json"
$ReceiptPath = Join-Path $PaperDir "PUBLICATION_RECEIPT.json"

function Log([string]$m) { Write-Host ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $m) }
function Save-State($s) { $s | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $StatePath -Encoding UTF8 }
function Set-Prop($obj,[string]$name,$value) { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force }

function Get-ZenodoToken {
    $tokenFile = Join-Path $env:USERPROFILE ".zenodo_token.dpapi"
    if (-not (Test-Path -LiteralPath $tokenFile)) { throw "Zenodo token missing. Run SAVE_ZENODO_TOKEN.ps1 once." }
    $enc = [IO.File]::ReadAllText($tokenFile).Trim()
    $sec = ConvertTo-SecureString -String $enc
    $bstr = [IntPtr]::Zero
    try {
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        if ($token.Length -lt 40) { throw "Stored Zenodo token is invalid (length=$($token.Length))." }
        return $token
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
        Remove-Variable sec,enc -ErrorAction SilentlyContinue
    }
}

function Zenodo-Json([string]$Method,[string]$Uri,$Body,[string]$Token) {
    $headers = @{ Authorization = "Bearer $Token" }
    if ($null -eq $Body) { return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers }
    $json = $Body | ConvertTo-Json -Depth 20
    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType "application/json" -Body $json
}

function Ensure-ZenodoDraft([string]$Kind,$State,[hashtable]$Metadata,[string]$Token) {
    $idName = "${Kind}_id"; $doiName = "${Kind}_doi"; $bucketName = "${Kind}_bucket"; $htmlName = "${Kind}_html"
    if (($State.PSObject.Properties.Name -contains $idName) -and $State.$idName) { Log "Reusing Zenodo $Kind draft id=$($State.$idName)"; return }
    Log "Creating Zenodo $Kind draft"
    $draft = Zenodo-Json "Post" "https://zenodo.org/api/deposit/depositions" @{} $Token
    $id = [string]$draft.id
    $Metadata["prereserve_doi"] = $true
    $updated = Zenodo-Json "Put" "https://zenodo.org/api/deposit/depositions/$id" @{metadata=$Metadata} $Token
    Set-Prop $State $idName $id
    Set-Prop $State $doiName ([string]$updated.metadata.prereserve_doi.doi)
    Set-Prop $State $bucketName ([string]$updated.links.bucket)
    Set-Prop $State $htmlName ([string]$updated.links.html)
    Save-State $State
    Log "Reserved $Kind DOI: $($State.$doiName)"
}

function Upload-File([string]$Bucket,[string]$Path,[string]$Token,[string]$ContentType) {
    $name = [IO.Path]::GetFileName($Path)
    $url = "$Bucket/$([Uri]::EscapeDataString($name))"
    $headers = @{ Authorization = "Bearer $Token" }
    Invoke-RestMethod -Method Put -Uri $url -Headers $headers -InFile $Path -ContentType $ContentType | Out-Null
}

# ----- Load and validate -----
if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Missing $ConfigPath" }
$cfg = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$pdfPath = Join-Path $PaperDir ([string]$cfg.pdf_file)
if (-not (Test-Path -LiteralPath $pdfPath)) { throw "PDF missing: $pdfPath" }

if (Test-Path -LiteralPath $StatePath) { $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json }
else { $state = [pscustomobject]@{status="STARTED"}; Save-State $state }
if (($state.PSObject.Properties.Name -contains "status") -and $state.status -eq "PUBLISHED") { Log "Already published."; Get-Content $ReceiptPath; exit 0 }

$token = Get-ZenodoToken
try {
    $headers = @{ Authorization = "Bearer $token" }
    Invoke-RestMethod -Method Get -Uri "https://zenodo.org/api/deposit/depositions" -Headers $headers | Out-Null
    Log "Zenodo authentication OK"

    $creator = @{name="Yonezu, Ryutaro"; affiliation="Independent Researcher"}
    $preMeta = @{
        upload_type="publication"; publication_type="preprint"; publication_date=[string]$cfg.publication_date;
        title=[string]$cfg.title; creators=@($creator); description=[string]$cfg.abstract; access_right="open";
        license="cc-by-4.0"; keywords=@($cfg.keywords)
    }
    $softMeta = @{
        upload_type="software"; publication_date=[string]$cfg.publication_date;
        title="$($cfg.title) - software and source package"; creators=@($creator);
        description="Source, publication metadata, and automation scripts associated with the preprint: $($cfg.title)";
        access_right="open"; license="mit"; keywords=@($cfg.keywords); version=[string]$cfg.version
    }

    Ensure-ZenodoDraft "preprint" $state $preMeta $token
    Ensure-ZenodoDraft "software" $state $softMeta $token
    $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json

    # ----- Generate DOI-aware repo metadata -----
    $repoFull = "$($cfg.github_owner)/$($cfg.repo_name)"
    $repoUrl = "https://github.com/$repoFull"
    $releaseUrl = "$repoUrl/releases/tag/$($cfg.version)"

    @"
# $($cfg.title)

**Author:** Ryutaro Yonezu  
**Affiliation:** Independent Researcher  
**Version:** $($cfg.version)

Preprint DOI: https://doi.org/$($state.preprint_doi)  
Software DOI: https://doi.org/$($state.software_doi)

## Main result

Stabilizing binary consensus is size-oblivious and needs exactly one bit of local state. Explicitly terminating binary consensus requires Omega(log n) local memory; when n is known as a non-uniform algorithm parameter, this is tight.

## Licenses

- Paper: CC BY 4.0
- Software / scripts: MIT

## Claim boundary

The proof techniques are standard. The claimed contribution is restricted to the tight local-space characterization in the specified binary-consensus model. Targeted prior-art screening found no direct match; novelty is not certified.
"@ | Set-Content -LiteralPath (Join-Path $PaperDir "README.md") -Encoding UTF8

    $zenodo = [ordered]@{
        creators=@(@{name="Yonezu, Ryutaro"; affiliation="Independent Researcher"});
        title="$($cfg.title) - software and source package"; version=[string]$cfg.version;
        access_right="open"; license="mit"; upload_type="software"; keywords=@($cfg.keywords);
        related_identifiers=@(@{identifier="10.5281/zenodo.$(($state.preprint_doi -split '\.')[-1])"; relation="isSupplementTo"})
    }
    $zenodo | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $PaperDir ".zenodo.json") -Encoding UTF8

    @"
cff-version: 1.2.0
message: "If you use this source package, please cite the associated preprint."
title: "$($cfg.title) - software and source package"
version: "$($cfg.version)"
doi: "$($state.software_doi)"
authors:
  - family-names: "Yonezu"
    given-names: "Ryutaro"
preferred-citation:
  type: article
  title: "$($cfg.title)"
  authors:
    - family-names: "Yonezu"
      given-names: "Ryutaro"
  year: 2026
  doi: "$($state.preprint_doi)"
"@ | Set-Content -LiteralPath (Join-Path $PaperDir "CITATION.cff") -Encoding UTF8

    # ----- GitHub CLI -----
    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $ghCmd) {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) { throw "GitHub CLI (gh) is missing and winget is unavailable." }
        Log "Installing GitHub CLI"
        & winget install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements
        $candidate = "C:\Program Files\GitHub CLI\gh.exe"
        if (Test-Path $candidate) { $gh = $candidate } else { throw "GitHub CLI installed but gh.exe was not found. Reopen PowerShell and rerun." }
    } else { $gh = $ghCmd.Source }

    & $gh auth status 2>$null
    if ($LASTEXITCODE -ne 0) {
        Log "GitHub authentication required (one time)"
        & $gh auth login --web --git-protocol https
        if ($LASTEXITCODE -ne 0) { throw "GitHub authentication failed." }
    }

    Set-Location $PaperDir
    if (-not (Test-Path (Join-Path $PaperDir ".git"))) { git init | Out-Null; git branch -M main }
    git add -A
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) { git commit -m "Prepare $($cfg.version) publication package" }

    & $gh repo view $repoFull 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        Log "Creating PRIVATE GitHub repository $repoFull"
        & $gh repo create $repoFull --private --description ([string]$cfg.repo_description) --source $PaperDir --remote origin --push
        if ($LASTEXITCODE -ne 0) { throw "GitHub repository creation failed." }
    } else {
        $remote = git remote get-url origin 2>$null
        if ($LASTEXITCODE -ne 0) { git remote add origin "https://github.com/$repoFull.git" }
        git push -u origin main
    }

    git rev-parse $($cfg.version) 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) { git tag -a $($cfg.version) -m $($cfg.version); git push origin $($cfg.version) }

    & $gh release view $($cfg.version) --repo $repoFull 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        Log "Creating GitHub release $($cfg.version) (repository remains private until -Publish)"
        & $gh release create $($cfg.version) --repo $repoFull --title $($cfg.version) --notes "Initial release for: $($cfg.title)"
        if ($LASTEXITCODE -ne 0) { throw "GitHub release creation failed." }
    }

    # ----- Cross-link Zenodo metadata -----
    $preMeta["related_identifiers"] = @(
        @{identifier=$state.software_doi; relation="isSupplementedBy"},
        @{identifier=$repoUrl; relation="isDocumentedBy"}
    )
    $softMeta["related_identifiers"] = @(
        @{identifier=$state.preprint_doi; relation="isSupplementTo"},
        @{identifier=$releaseUrl; relation="isAlternateIdentifier"}
    )
    Zenodo-Json "Put" "https://zenodo.org/api/deposit/depositions/$($state.preprint_id)" @{metadata=$preMeta} $token | Out-Null
    Zenodo-Json "Put" "https://zenodo.org/api/deposit/depositions/$($state.software_id)" @{metadata=$softMeta} $token | Out-Null

    # ----- Exact tagged source ZIP -----
    $zipPath = Join-Path $PaperDir "$($cfg.repo_name)-$($cfg.version).release.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    git archive --format=zip --output="$zipPath" $($cfg.version)
    if ($LASTEXITCODE -ne 0) { throw "git archive failed." }

    Log "Uploading PDF to Zenodo preprint draft"
    Upload-File $state.preprint_bucket $pdfPath $token "application/octet-stream"
    Log "Uploading tagged source ZIP to Zenodo software draft"
    Upload-File $state.software_bucket $zipPath $token "application/octet-stream"

    Set-Prop $state "repo_url" $repoUrl
    Set-Prop $state "release_url" $releaseUrl
    Set-Prop $state "status" "DRAFTS_READY"
    Save-State $state

    if (-not $Publish) {
        Write-Host ""
        Write-Host "DRAFTS_READY - NOTHING HAS BEEN PUBLISHED ON ZENODO"
        Write-Host "GitHub repository is PRIVATE."
        Write-Host "Preprint draft: $($state.preprint_html)"
        Write-Host "Software draft: $($state.software_html)"
        Write-Host "Preprint DOI reserved: $($state.preprint_doi)"
        Write-Host "Software DOI reserved: $($state.software_doi)"
        Write-Host ""
        Write-Host "After review, rerun with:"
        Write-Host "  & `"$($MyInvocation.MyCommand.Path)`" -Publish"
        exit 0
    }

    Log "Making GitHub repository public"
    & $gh repo edit $repoFull --visibility public --accept-visibility-change-consequences
    if ($LASTEXITCODE -ne 0) { throw "Could not make GitHub repository public; Zenodo was NOT published." }

    Log "Publishing Zenodo preprint"
    $prePub = Zenodo-Json "Post" "https://zenodo.org/api/deposit/depositions/$($state.preprint_id)/actions/publish" $null $token
    Log "Publishing Zenodo software"
    $softPub = Zenodo-Json "Post" "https://zenodo.org/api/deposit/depositions/$($state.software_id)/actions/publish" $null $token

    Set-Prop $state "status" "PUBLISHED"
    Save-State $state

    $receipt = [ordered]@{
        title=[string]$cfg.title; author="Ryutaro Yonezu"; affiliation="Independent Researcher";
        github_repository=$repoUrl; github_release=$releaseUrl; preprint_doi=$state.preprint_doi;
        software_doi=$state.software_doi; version=[string]$cfg.version; published_at=(Get-Date).ToString("o")
    }
    $receipt | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ReceiptPath -Encoding UTF8

    Write-Host ""
    Write-Host "PUBLICATION_COMPLETE"
    Write-Host "GitHub:       $repoUrl"
    Write-Host "Release:      $releaseUrl"
    Write-Host "Preprint DOI: https://doi.org/$($state.preprint_doi)"
    Write-Host "Software DOI: https://doi.org/$($state.software_doi)"
}
finally {
    Remove-Variable token -ErrorAction SilentlyContinue
}

