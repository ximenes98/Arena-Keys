# Arena Key Steam Plugin - Instalador
# Criado em: Outubro 2025

# Função para mostrar checklist
function Write-Checklist {
    param([string]$Message, [string]$Status = "pending")
    
    $symbol = switch ($Status) {
        "pending"  { "[ ]" }
        "progress" { "[~]" }
        "done"     { "[✓]" }
        "error"    { "[X]" }
    }
    
    $color = switch ($Status) {
        "pending"  { "Gray" }
        "progress" { "Yellow" }
        "done"     { "Green" }
        "error"    { "Red" }
    }
    
    Write-Host "$symbol $Message" -ForegroundColor $color
}

# Função para mostrar erro
function Write-Error-Message {
    param([string]$Message)
    Write-Host "`n[ERRO] $Message" -ForegroundColor Red
}

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   ARENA KEY STEAM PLUGIN - v1.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Mostrar checklist inicial
Write-Host "Tarefas:" -ForegroundColor White
Write-Checklist "Encerrar processos da Steam" "pending"
Write-Checklist "Localizar instalação da Steam" "pending"
Write-Checklist "Baixar Arena Key Plugin" "pending"
Write-Checklist "Extrair arquivos" "pending"
Write-Checklist "Copiar para Steam" "pending"
Write-Checklist "Iniciar Steam" "pending"
Write-Host ""

try {
    # Passo 1: Encerrar processos da Steam
    Write-Host "`r[~] Encerrar processos da Steam" -ForegroundColor Yellow -NoNewline
    $steamProcesses = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
    
    if ($steamProcesses) {
        foreach ($process in $steamProcesses) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    }
    Write-Host "`r[✓] Encerrar processos da Steam          " -ForegroundColor Green

    # Passo 2: Encontrar instalação da Steam no registro
    Write-Host "[~] Localizar instalação da Steam" -ForegroundColor Yellow -NoNewline
    
    $steamPath = $null
    $registryPaths = @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )
    
    foreach ($regPath in $registryPaths) {
        try {
            $installPath = Get-ItemProperty -Path $regPath -Name "InstallPath" -ErrorAction SilentlyContinue
            if ($installPath -and (Test-Path $installPath.InstallPath)) {
                $steamPath = $installPath.InstallPath
                break
            }
        } catch {
            continue
        }
    }
    
    if (-not $steamPath) {
        throw "Steam não encontrada no registro. Verifique se está instalada corretamente."
    }
    
    Write-Host "`r[✓] Localizar instalação da Steam     " -ForegroundColor Green
    Write-Host "    → $steamPath" -ForegroundColor DarkGray

    # Passo 3: Baixar arquivo Arena Keys
    Write-Host "[~] Baixar Arena Key Plugin" -ForegroundColor Yellow -NoNewline
    $downloadUrl = "https://github.com/ximenes98/Arena-Keys/releases/download/v1.0.2/Steam.zip"
    $zipPath = Join-Path $env:TEMP "Steam_ArenaKeys.zip"
    $extractTemp = Join-Path $env:TEMP "Steam_ArenaKeys_Extract"
    
    # Remover arquivos anteriores se existirem
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    if (Test-Path $extractTemp) {
        Remove-Item $extractTemp -Recurse -Force
    }
    
    # Baixar arquivo
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Host "`r[✓] Baixar Arena Key Plugin          " -ForegroundColor Green
    } catch {
        throw "Falha ao baixar o arquivo: $($_.Exception.Message)"
    }

    # Verificar e remover hid.dll existente
    $hidDllPath = Join-Path $steamPath "hid.dll"
    if (Test-Path $hidDllPath) {
        Write-Host "[~] Removendo hid.dll existente" -ForegroundColor Yellow -NoNewline
        Remove-Item $hidDllPath -Force -ErrorAction SilentlyContinue
        Write-Host "`r[✓] Removendo hid.dll existente      " -ForegroundColor Green
    }

    # Passo 4: Extrair conteúdo para a raiz da Steam
    Write-Host "[~] Extrair arquivos" -ForegroundColor Yellow -NoNewline
    
    # Verificar se o arquivo foi baixado
    if (-not (Test-Path $zipPath)) {
        throw "Arquivo não foi baixado corretamente."
    }
    
    # Extrair para pasta temporária primeiro
    try {
        Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force
        Write-Host "`r[✓] Extrair arquivos                 " -ForegroundColor Green
    } catch {
        throw "Falha ao extrair o arquivo: $($_.Exception.Message)"
    }
    
    # Copiar arquivos da pasta temporária para a Steam (sobrescrevendo existentes)
    Write-Host "[~] Copiar para Steam" -ForegroundColor Yellow -NoNewline
    try {
        # Primeiro, copiar todos os arquivos e pastas diretamente
        $extractedItems = Get-ChildItem -Path $extractTemp -Force
        
        foreach ($item in $extractedItems) {
            $targetPath = Join-Path $steamPath $item.Name
            
            if ($item.PSIsContainer) {
                # É uma pasta - copiar recursivamente
                Copy-Item -Path $item.FullName -Destination $steamPath -Recurse -Force
            } else {
                # É um arquivo - copiar e sobrescrever
                Copy-Item -Path $item.FullName -Destination $targetPath -Force
            }
        }
        
        Write-Host "`r[✓] Copiar para Steam                " -ForegroundColor Green
    } catch {
        throw "Falha ao copiar arquivos: $($_.Exception.Message)"
    }

    # Renomear hid.txt para hid.dll
    $hidTxtPath = Join-Path $steamPath "hid.txt"
    $hidDllNewPath = Join-Path $steamPath "hid.dll"
    
    if (Test-Path $hidTxtPath) {
        Write-Host "[~] Configurando hid.dll" -ForegroundColor Yellow -NoNewline
        Rename-Item -Path $hidTxtPath -NewName "hid.dll" -Force
        Write-Host "`r[✓] Configurando hid.dll             " -ForegroundColor Green
    }
    
    # Limpar arquivo temporário
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

    # Passo 5: Iniciar Steam novamente
    Write-Host "[~] Iniciar Steam" -ForegroundColor Yellow -NoNewline
    $steamExe = Join-Path $steamPath "steam.exe"
    
    if (Test-Path $steamExe) {
        Start-Process -FilePath $steamExe -WorkingDirectory $steamPath
        Start-Sleep -Seconds 1
        Write-Host "`r[✓] Iniciar Steam                    " -ForegroundColor Green
    } else {
        Write-Error-Message "Executável da Steam não encontrado em: $steamExe"
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   INSTALAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Error-Message $_.Exception.Message
    Write-Host ""
    Write-Host "Instalação falhou. Pressione qualquer tecla para sair..." -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
