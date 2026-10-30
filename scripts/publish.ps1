$ErrorActionPreference = 'Continue'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$repoSafePath = $projectRoot.Replace('\', '/')

function Invoke-RepoGit {
    # Trust this shared repository only for this command, without changing global settings.
    & git -c "safe.directory=$repoSafePath" @args
}

function Run-Git {
    Invoke-RepoGit @args
    if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($args -join ' ')) }
}

if (-not (Test-Path -LiteralPath '.git')) { Run-Git init -b main }
$branchOutput = Invoke-RepoGit branch --show-current
if ($LASTEXITCODE -ne 0) { throw 'Cannot read the local repository.' }
$branch = ([string]$branchOutput).Trim()
if ($branch -ne 'main') { throw 'Expected branch main. No branch was changed automatically.' }

$remoteUrl = Invoke-RepoGit remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
    Run-Git remote add origin 'https://github.com/Web3Hippo/insuarance.git'
} elseif ($remoteUrl.TrimEnd('/') -notin @('https://github.com/Web3Hippo/insuarance.git', 'https://github.com/Web3Hippo/insuarance', 'git@github.com:Web3Hippo/insuarance.git')) {
    throw 'origin points to another repository. It was not changed.'
}

& gh auth status
if ($LASTEXITCODE -ne 0) {
    & gh auth login --hostname github.com --git-protocol https --web
    if ($LASTEXITCODE -ne 0) { throw 'GitHub login did not complete.' }
}
& gh auth setup-git
if ($LASTEXITCODE -ne 0) { throw 'Git credential setup failed.' }

& node scripts/prepare-site.cjs
if ($LASTEXITCODE -ne 0) { throw 'Site preparation failed.' }
Run-Git add .gitignore README.md index.html assets scripts .github
Invoke-RepoGit diff --cached --quiet
if ($LASTEXITCODE -eq 1) {
    Run-Git commit -m 'Add insurance comparison page and GitHub Pages deployment'
} elseif ($LASTEXITCODE -ne 0) {
    throw 'Cannot inspect staged changes.'
}

# A normal push refuses to overwrite unrelated remote work; never force-push.
Run-Git push -u origin main

& gh api 'repos/Web3Hippo/insuarance/pages' --silent 2>$null
$pagesMethod = if ($LASTEXITCODE -eq 0) { 'PUT' } else { 'POST' }
'{"build_type":"workflow"}' | & gh api 'repos/Web3Hippo/insuarance/pages' --method $pagesMethod --input - --silent
if ($LASTEXITCODE -ne 0) {
    throw 'Push completed, but Pages setup failed. Set Settings > Pages > Source to GitHub Actions.'
}
& gh workflow run pages.yml --ref main --repo Web3Hippo/insuarance
if ($LASTEXITCODE -ne 0) {
    Write-Warning 'Pages was configured. Check the Deploy comparison page workflow in GitHub Actions.'
}
Write-Output 'Push complete. Follow deployment: https://github.com/Web3Hippo/insuarance/actions'
Write-Output 'Website after deployment: https://web3hippo.github.io/insuarance/'
