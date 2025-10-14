# Script para baixar e instalar arquivos na pasta da Steam
# API: https://api.github.com/repos/ximenes98/Arena-Keys/releases

$apiUrl = "https://api.github.com/repos/ximenes98/Arena-Keys/releases"
$packageName = "steam.zip"

# Define cores
$BoldPurple = [char]27 + '[38;5;219m'
$BoldGreen = [char]27 + '[1;32m'
$BoldYellow = [char]27 + '[1;33m'
$BoldRed = [char]27 + '[1;31m'
$ResetColor = [char]27 + '[0m'

Add-Type -AssemblyName System.IO.Compression.FileSystem

Write-Host "${BoldPurple}===================================${ResetColor}"
Write-Host "${BoldPurple}    Steam Package Installer${ResetColor}"
Write-Host "${BoldPurple}===================================${ResetColor}`n"

# Função para fechar o Steam
function Close-SteamProcess {
    $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    if ($steamProcess) {
        Write-Host "${BoldYellow}[*]${ResetColor} Fechando processo do Steam..."
        Stop-Process -Name "steam" -Force
        Start-Sleep -Seconds 2
        Write-Host "${BoldGreen}[+]${ResetColor} Steam fechado com sucesso.`n"
    }
}

# Função para iniciar o Steam
function Start-Steam {
    param([string]$steamPath)
    $steamExe = Join-Path -Path $steamPath -ChildPath "Steam.exe"
    if (Test-Path -Path $steamExe) {
        Write-Host "${BoldGreen}[+]${ResetColor} Iniciando Steam..."
        Start-Process -FilePath $steamExe
    } else {
        Write-Host "${BoldRed}[!]${ResetColor} Steam.exe não encontrado em: $steamExe"
    }
}

# Fechar Steam antes de instalar
Close-SteamProcess

# Buscar caminho da Steam no registro
Write-Host "${BoldPurple}[*]${ResetColor} Procurando instalação do Steam..."
$steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath

if (-not $steamPath) {
    Write-Host "${BoldRed}[!]${ResetColor} Steam não encontrado no registro."
    Write-Host "${BoldYellow}[?]${ResetColor} Por favor, certifique-se de que o Steam está instalado."
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "${BoldGreen}[+]${ResetColor} Steam encontrado em: ${BoldYellow}$steamPath${ResetColor}`n"

# Buscar última release
Write-Host "${BoldPurple}[*]${ResetColor} Buscando última versão..."
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell-Installer/1.0" }
    $latestRelease = $response | Where-Object { -not $_.prerelease } | Sort-Object -Property created_at -Descending | Select-Object -First 1
    
    if (-not $latestRelease) {
        Write-Host "${BoldRed}[!]${ResetColor} Nenhuma release encontrada."
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    
    $releaseTag = $latestRelease.tag_name
    Write-Host "${BoldGreen}[+]${ResetColor} Versão encontrada: ${BoldYellow}$releaseTag${ResetColor}"
} catch {
    Write-Host "${BoldRed}[!]${ResetColor} Erro ao buscar releases: $_"
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Buscar arquivo steam.zip
$targetAsset = $latestRelease.assets | Where-Object { $_.name -eq $packageName }

if (-not $targetAsset) {
    Write-Host "${BoldRed}[!]${ResetColor} Arquivo '$packageName' não encontrado na release."
    Write-Host "${BoldYellow}[?]${ResetColor} Arquivos disponíveis:"
    $latestRelease.assets | ForEach-Object { Write-Host "    - $($_.name)" }
    Read-Host "Pressione Enter para sair"
    exit 1
}

$downloadUrl = $targetAsset.browser_download_url
$fileSize = [math]::Round($targetAsset.size / 1MB, 2)
Write-Host "${BoldGreen}[+]${ResetColor} Arquivo encontrado: $packageName (${fileSize}MB)`n"

# Baixar arquivo
$outputFile = Join-Path -Path $steamPath -ChildPath $packageName
Write-Host "${BoldPurple}[*]${ResetColor} Baixando arquivo..."
Write-Host "${BoldYellow}    URL:${ResetColor} $downloadUrl"
Write-Host "${BoldYellow}    Destino:${ResetColor} $outputFile`n"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile -UserAgent "PowerShell-Installer/1.0"
    Write-Host "${BoldGreen}[+]${ResetColor} Download concluído!`n"
} catch {
    Write-Host "${BoldRed}[!]${ResetColor} Erro ao baixar arquivo: $_"
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Descompactar arquivo
Write-Host "${BoldPurple}[*]${ResetColor} Descompactando arquivo..."
try {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($outputFile, $steamPath, $true)
    Write-Host "${BoldGreen}[+]${ResetColor} Arquivo descompactado com sucesso!`n"
} catch {
    Write-Host "${BoldRed}[!]${ResetColor} Erro ao descompactar: $_"
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Remover arquivo zip
Write-Host "${BoldPurple}[*]${ResetColor} Limpando arquivos temporários..."
if (Test-Path -Path $outputFile) {
    Remove-Item -Path $outputFile -Force
    Write-Host "${BoldGreen}[+]${ResetColor} Arquivo zip removido.`n"
}

# Finalizar
Write-Host "${BoldGreen}===================================${ResetColor}"
Write-Host "${BoldGreen}   Instalação Concluída!${ResetColor}"
Write-Host "${BoldGreen}===================================${ResetColor}`n"

# Iniciar Steam novamente
Start-Steam -steamPath $steamPath

Write-Host "${BoldYellow}[!]${ResetColor} Steam foi reiniciado. Aguarde o carregamento completo.`n"
