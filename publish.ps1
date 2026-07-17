# =====================================================================
#  publish.ps1  -  Publication du site utilisateur GitHub Pages
#  pour la verification du domaine OAuth (nicob-droid.github.io)
# ---------------------------------------------------------------------
#  Utilisation :
#     cd C:\Development\Android\Melodie\gh-user-site
#     .\publish.ps1
#
#  Options :
#     .\publish.ps1 -Message "mon message de commit"
#     .\publish.ps1 -GitHubUser autreCompte
# =====================================================================

[CmdletBinding()]
param(
    [string]$GitHubUser = "nicob-droid",
    [string]$Message    = "Mise a jour du site (verification OAuth)"
)

$ErrorActionPreference = "Stop"

function Write-Step($text) { Write-Host "`n==> $text" -ForegroundColor Cyan }
function Write-Ok($text)   { Write-Host "    OK  $text" -ForegroundColor Green }
function Write-Warn($text) { Write-Host "    !!  $text" -ForegroundColor Yellow }

# --- Verifications prealables ----------------------------------------
$repoName = "$GitHubUser.github.io"
$remoteUrl = "https://github.com/$GitHubUser/$repoName.git"

# On se place dans le dossier du script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir
Write-Step "Dossier de travail : $scriptDir"

# Verifie que git est installe
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git n'est pas installe ou introuvable dans le PATH. Installez Git puis relancez."
}
Write-Ok "git detecte : $(git --version)"

# Verifie que les fichiers essentiels sont presents
$required = @("index.html", "google62d797a6a60bee31.html", "oauth-pages\index.html")
foreach ($f in $required) {
    if (-not (Test-Path (Join-Path $scriptDir $f))) {
        throw "Fichier manquant : $f. Le dossier gh-user-site est incomplet."
    }
}
Write-Ok "Fichiers requis presents"

# --- Initialisation du depot -----------------------------------------
if (-not (Test-Path (Join-Path $scriptDir ".git"))) {
    Write-Step "Initialisation du depot git"
    git init | Out-Null
    git branch -M main
    Write-Ok "Depot initialise (branche main)"
} else {
    Write-Ok "Depot git deja initialise"
    # S'assurer qu'on est bien sur main
    $current = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($current -ne "main") { git branch -M main }
}

# --- Configuration du remote -----------------------------------------
$existingRemote = git remote 2>$null
if ($existingRemote -contains "origin") {
    $currentRemote = (git remote get-url origin).Trim()
    if ($currentRemote -ne $remoteUrl) {
        Write-Warn "origin pointe vers $currentRemote -> mise a jour vers $remoteUrl"
        git remote set-url origin $remoteUrl
    } else {
        Write-Ok "origin deja configure : $remoteUrl"
    }
} else {
    git remote add origin $remoteUrl
    Write-Ok "origin ajoute : $remoteUrl"
}

# --- Commit -----------------------------------------------------------
Write-Step "Ajout et commit des fichiers"
git add -A

# git diff --cached retourne un code de sortie != 0 s'il y a des changements
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Warn "Aucune modification a commiter (rien de nouveau)."
} else {
    git commit -m $Message | Out-Null
    Write-Ok "Commit cree : $Message"
}

# --- Push -------------------------------------------------------------
Write-Step "Envoi vers GitHub ($remoteUrl)"
Write-Warn "Assurez-vous d'avoir cree le depot PUBLIC nomme exactement : $repoName"
git push -u origin main

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nLe push a echoue." -ForegroundColor Red
    Write-Host "Causes frequentes :" -ForegroundColor Red
    Write-Host "  - Le depot '$repoName' n'existe pas encore sur GitHub (creez-le, public)." -ForegroundColor Red
    Write-Host "  - Authentification refusee (utilisez un Personal Access Token comme mot de passe)." -ForegroundColor Red
    exit 1
}

Write-Ok "Push termine avec succes"

# --- Rappel des etapes suivantes -------------------------------------
Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host " ETAPES SUIVANTES" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " 1. GitHub -> Settings -> Pages : Source = branche 'main', dossier '/ (root)'"
Write-Host " 2. Attendez 1-2 min, puis verifiez (doit renvoyer 200) :"
Write-Host "      https://$repoName/google62d797a6a60bee31.html"
Write-Host " 3. Search Console : ajoutez la propriete 'Prefixe URL' :"
Write-Host "      https://$repoName/"
Write-Host "      puis validez (methode Fichier HTML)."
Write-Host " 4. Ecran de consentement OAuth : mettez les URLs a la racine :"
Write-Host "      https://$repoName/oauth-pages/index.html"
Write-Host "      https://$repoName/oauth-pages/privacy.html"
Write-Host "      https://$repoName/oauth-pages/terms.html"
Write-Host "      Domaine autorise : $repoName"
Write-Host "=====================================================================" -ForegroundColor Cyan

