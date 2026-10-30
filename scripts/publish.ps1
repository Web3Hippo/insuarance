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

function Sync-RemoteMain {
    Run-Git fetch --no-tags origin
    Invoke-RepoGit show-ref --verify --quiet refs/remotes/origin/main
    $remoteRefExit = $LASTEXITCODE
    if ($remoteRefExit -eq 1) { return }
    if ($remoteRefExit -ne 0) { throw 'Cannot inspect origin/main.' }

    # The local site and GitHub's starter commit may have independent roots.
    Invoke-RepoGit merge --allow-unrelated-histories --no-edit --no-overwrite-ignore origin/main
    if ($LASTEXITCODE -eq 0) { return }

    $conflicts = @(Invoke-RepoGit diff --name-only --diff-filter=U)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect merge conflicts.' }
    if ($conflicts.Count -eq 1 -and $conflicts[0] -ceq 'README.md') {
        # Keep the requested full site README instead of GitHub's starter README.
        Run-Git checkout --ours -- README.md
        Run-Git add -- README.md
        Run-Git commit --no-edit
        return
    }

    Invoke-RepoGit rev-parse --verify --quiet MERGE_HEAD *> $null
    if ($LASTEXITCODE -eq 0) { Run-Git merge --abort }
    throw 'Remote merge failed. No push was attempted. Inspect the Git output above.'
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

# Preserve remote commits before a normal push; never force-push.
Sync-RemoteMain
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
