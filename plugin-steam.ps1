# Script para atualizar Steam com Arena Keys
# Criado em: Outubro 2025

# Função para mostrar progresso
function Write-Progress-Message {
    param([string]$Message, [string]$Color = "Green")
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color
}

# Função para mostrar erro
function Write-Error-Message {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] ERRO: $Message" -ForegroundColor Red
}

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    STEAM ARENA KEYS UPDATER v1.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Passo 1: Encerrar processos da Steam
    Write-Progress-Message "Encerrando todos os processos da Steam..."
    $steamProcesses = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
    
    if ($steamProcesses) {
        foreach ($process in $steamProcesses) {
            Write-Progress-Message "Encerrando processo: $($process.ProcessName)"
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 3
        Write-Progress-Message "Processos da Steam encerrados com sucesso!" -Color "Yellow"
    } else {
        Write-Progress-Message "Nenhum processo da Steam encontrado em execução"
    }

    # Passo 2: Encontrar instalação da Steam no registro
    Write-Progress-Message "Procurando instalação da Steam no registro..."
    
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
    
    Write-Progress-Message "Steam encontrada em: $steamPath" -Color "Yellow"

    # Passo 3: Baixar arquivo Arena Keys
    Write-Progress-Message "Baixando Arena Keys..."
    $downloadUrl = "https://github.com/ximenes98/Arena-Keys/releases/download/v1.0.1/Steam.zip"
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
        Write-Progress-Message "Download concluído!" -Color "Yellow"
    } catch {
        throw "Falha ao baixar o arquivo: $($_.Exception.Message)"
    }

    # Passo 4: Extrair conteúdo para a raiz da Steam
    Write-Progress-Message "Extraindo arquivos para a Steam..."
    
    # Verificar se o arquivo foi baixado
    if (-not (Test-Path $zipPath)) {
        throw "Arquivo não foi baixado corretamente."
    }
    
    # Extrair para pasta temporária primeiro
    try {
        Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force
        Write-Progress-Message "Arquivos extraídos temporariamente" -Color "Cyan"
    } catch {
        throw "Falha ao extrair o arquivo: $($_.Exception.Message)"
    }
    
    # Copiar arquivos da pasta temporária para a Steam (sobrescrevendo existentes)
    Write-Progress-Message "Copiando arquivos para o diretório da Steam..."
    try {
        # Primeiro, copiar todos os arquivos e pastas diretamente
        $extractedItems = Get-ChildItem -Path $extractTemp -Force
        
        foreach ($item in $extractedItems) {
            $targetPath = Join-Path $steamPath $item.Name
            
            if ($item.PSIsContainer) {
                # É uma pasta - copiar recursivamente
                Write-Progress-Message "  Copiando pasta: $($item.Name)" -Color "Cyan"
                Copy-Item -Path $item.FullName -Destination $steamPath -Recurse -Force
            } else {
                # É um arquivo - copiar e sobrescrever
                Copy-Item -Path $item.FullName -Destination $targetPath -Force
                Write-Progress-Message "  Copiado: $($item.Name)" -Color "DarkGray"
            }
        }
        
        Write-Progress-Message "Arquivos copiados com sucesso!" -Color "Yellow"
    } catch {
        throw "Falha ao copiar arquivos: $($_.Exception.Message)"
    }
    
    # Limpar arquivo temporário
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

    # Passo 5: Iniciar Steam novamente
    Write-Progress-Message "Iniciando Steam..."
    $steamExe = Join-Path $steamPath "steam.exe"
    
    if (Test-Path $steamExe) {
        Start-Process -FilePath $steamExe -WorkingDirectory $steamPath
        Write-Progress-Message "Steam iniciada com sucesso!" -Color "Green"
    } else {
        Write-Error-Message "Executável da Steam não encontrado em: $steamExe"
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "    ATUALIZAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    
} catch {
    Write-Error-Message $_.Exception.Message
    Write-Host ""
    Write-Host "Script falhou. Pressione qualquer tecla para sair..." -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
