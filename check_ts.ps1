param(
    [int]$WarningThreshold = 2,
    [int]$CriticalThreshold = 3
)

# Ejecutar `quser` y capturar la salida
$quserOutput = quser 2>&1 | Out-String

# Verificar si `quser` no devolvió ninguna línea útil
if (-not $quserOutput -or $quserOutput -notmatch "USERNAME") {
    Write-Output "OK: No hay usuarios conectados"
    exit 0
}

# Convertir la salida de `quser` en un array de líneas
$lines = $quserOutput -split "`r?`n"

# Inicializar listas para los usuarios activos y desconectados
$activeUsers = @()
$disconnectedUsers = @()

# Procesar línea por línea
$lines | ForEach-Object {
    $line = $_.Trim()

    # Ignorar líneas vacías o encabezados
    if ($line -match "USERNAME" -or $line -eq "") {
        return
    }

    # Procesar la línea, dividir en columnas usando espacios consecutivos como separador
    $columns = $line -split '\s{2,}'

    # Validar que la línea tiene al menos 4 columnas
    if ($columns.Count -ge 4) {
        # Manejar el caso de `>` delante del nombre de usuario
        $username = $columns[0] -replace '^>', ''
        $state = $columns[3]

        # Clasificar el usuario según el estado
        if ($state -eq "Active") {
            $activeUsers += $username
        } else {
            $disconnectedUsers += $username
        }
    } else {
        Write-Host "No se pudo procesar la línea: $line"
    }
}

# Contar usuarios totales, activos y desconectados
$totalUsers = $activeUsers.Count + $disconnectedUsers.Count
$activeCount = $activeUsers.Count
$disconnectedCount = $disconnectedUsers.Count

# Crear listas de usuarios por estado
$activeList = if ($activeUsers.Count -gt 0) { $activeUsers -join ', ' } else { 'Ninguno' }
$disconnectedList = if ($disconnectedUsers.Count -gt 0) { $disconnectedUsers -join ', ' } else { 'Ninguno' }

# Evaluar los umbrales para usuarios totales
if ($totalUsers -ge $CriticalThreshold) {
    Write-Output "CRITICAL: Hay $totalUsers usuarios totales ($activeCount activos: $activeList, $disconnectedCount desconectados: $disconnectedList)"
    exit 2
} elseif ($totalUsers -ge $WarningThreshold) {
    Write-Output "WARNING: Hay $totalUsers usuarios totales ($activeCount activos: $activeList, $disconnectedCount desconectados: $disconnectedList)"
    exit 1
} else {
    Write-Output "OK: Hay $totalUsers usuarios totales ($activeCount activos: $activeList, $disconnectedCount desconectados: $disconnectedList)"
    exit 0
}
