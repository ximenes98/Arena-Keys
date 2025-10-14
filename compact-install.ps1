# Arena Key Steam Plugin - Instalador
# Criado em: Outubro 2025

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

try {
    # Passo 1: Encerrar processos da Steam
    Write-Host "[~] Encerrar processos da Steam" -ForegroundColor Yellow -NoNewline
    $steamProcesses = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
    
    if ($steamProcesses) {
        foreach ($process in $steamProcesses) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    }
    Write-Host "`r[✓] Encerrar processos da Steam          " -ForegroundColor Green

    # Passo 2: Localizar instalação da Steam no registro
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

    # Passo 3: Verificar e remover hid.dll existente
    $hidDllPath = Join-Path $steamPath "hid.dll"
    if (Test-Path $hidDllPath) {
        Write-Host "[~] Removendo hid.dll existente" -ForegroundColor Yellow -NoNewline
        Remove-Item $hidDllPath -Force -ErrorAction SilentlyContinue
        Write-Host "`r[✓] Removendo hid.dll existente      " -ForegroundColor Green
    }

    # Passo 4: Baixar arquivo ZIP
    Write-Host "[~] Baixar Arena Key Plugin" -ForegroundColor Yellow -NoNewline
    $downloadUrl = "https://github.com/ximenes98/Arena-Keys/releases/download/v1.0.4/Steam.zip"
    $zipPath = Join-Path $steamPath "Steam.zip"
    
    # Remover arquivo anterior se existir
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    # Baixar arquivo para a raiz da Steam
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Host "`r[✓] Baixar Arena Key Plugin          " -ForegroundColor Green
    } catch {
        throw "Falha ao baixar o arquivo: $($_.Exception.Message)"
    }

    # Passo 5: Extrair ZIP para a raiz da Steam
    Write-Host "[~] Extrair arquivos para Steam" -ForegroundColor Yellow -NoNewline
    
    if (-not (Test-Path $zipPath)) {
        throw "Arquivo ZIP não foi baixado corretamente."
    }
    
    try {
        Expand-Archive -Path $zipPath -DestinationPath $steamPath -Force
        Write-Host "`r[✓] Extrair arquivos para Steam      " -ForegroundColor Green
    } catch {
        throw "Falha ao extrair o arquivo: $($_.Exception.Message)"
    }

    # Passo 6: Renomear hid.txt para hid.dll
    $hidTxtPath = Join-Path $steamPath "hid.txt"
    
    if (Test-Path $hidTxtPath) {
        Write-Host "[~] Configurando hid.dll" -ForegroundColor Yellow -NoNewline
        Rename-Item -Path $hidTxtPath -NewName "hid.dll" -Force
        Write-Host "`r[✓] Configurando hid.dll             " -ForegroundColor Green
    }

    # Passo 7: Apagar arquivo ZIP
    Write-Host "[~] Limpando arquivos temporários" -ForegroundColor Yellow -NoNewline
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "`r[✓] Limpando arquivos temporários    " -ForegroundColor Green

    # Passo 8: Iniciar Steam
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
