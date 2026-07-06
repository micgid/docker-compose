<#
.SYNOPSIS
    Sauvegarde (BACKUP DATABASE) toutes les bases utilisateur d'une instance SQL Server.

.DESCRIPTION
    Se connecte a l'instance SQL Server indiquee, avec authentification SQL Server si
    -Username/-Password sont fournis, sinon avec le compte Windows courant (authentification integree).
    Enumere toutes les bases utilisateur en ligne (les bases systeme master/model/msdb et tempdb
    sont exclues) et effectue un backup complet de chacune vers le dossier de destination indique.

.PARAMETER ServerInstance
    Nom ou adresse de l'instance SQL Server, ex: "localhost", "localhost,1433", "MONSERVEUR\SQL2022".

.PARAMETER Username
    Login SQL Server. Laisser vide (avec -Password vide) pour utiliser l'authentification Windows.

.PARAMETER Password
    Mot de passe SQL Server. Laisser vide (avec -Username vide) pour utiliser l'authentification Windows.

.PARAMETER BackupPath
    Dossier de destination des fichiers .bak. Cree automatiquement s'il n'existe pas.

.EXAMPLE
    .\Backup-AllDatabases.ps1 -ServerInstance "localhost,1433" -BackupPath "D:\Backups\SQL"
    Sauvegarde toutes les bases avec le compte Windows courant.

.EXAMPLE
    .\Backup-AllDatabases.ps1 -ServerInstance "localhost,1433" -Username "sa" -Password "MonMotDePasse" -BackupPath "D:\Backups\SQL"
    Sauvegarde toutes les bases avec le login SQL "sa".
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [string]$Username = "",

    [Parameter(Mandatory = $false)]
    [string]$Password = "",

    [Parameter(Mandatory = $true)]
    [string]$BackupPath
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# --- Construction de la chaine de connexion ---
$useWindowsAuth = [string]::IsNullOrWhiteSpace($Username) -and [string]::IsNullOrWhiteSpace($Password)

if ($useWindowsAuth) {
    Write-Log "Authentification Windows (compte courant) utilisee."
    $connectionString = "Server=$ServerInstance;Database=master;Integrated Security=True;TrustServerCertificate=True;Connect Timeout=30;"
}
else {
    if ([string]::IsNullOrWhiteSpace($Username) -or [string]::IsNullOrWhiteSpace($Password)) {
        Write-Log "Username et Password doivent etre tous les deux renseignes, ou tous les deux vides." "ERROR"
        exit 1
    }
    Write-Log "Authentification SQL Server utilisee (login: $Username)."
    $connectionString = "Server=$ServerInstance;Database=master;User Id=$Username;Password=$Password;TrustServerCertificate=True;Connect Timeout=30;"
}

# --- Preparation du dossier de destination ---
if (-not (Test-Path -LiteralPath $BackupPath)) {
    Write-Log "Creation du dossier de destination: $BackupPath"
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
}
$BackupPath = (Resolve-Path -LiteralPath $BackupPath).Path

Add-Type -AssemblyName "System.Data"

$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString

try {
    $connection.Open()
}
catch {
    Write-Log "Impossible de se connecter a '$ServerInstance': $($_.Exception.Message)" "ERROR"
    exit 1
}

Write-Log "Connecte a '$ServerInstance'."

# --- Recuperation des bases utilisateur en ligne (hors master/model/msdb/tempdb) ---
$listCommand = $connection.CreateCommand()
$listCommand.CommandText = @"
SELECT name
FROM sys.databases
WHERE database_id > 4
  AND state = 0
  AND name <> 'tempdb'
ORDER BY name;
"@

$databases = New-Object System.Collections.Generic.List[string]
$reader = $listCommand.ExecuteReader()
try {
    while ($reader.Read()) {
        $databases.Add($reader.GetString(0))
    }
}
finally {
    $reader.Close()
}

if ($databases.Count -eq 0) {
    Write-Log "Aucune base utilisateur trouvee sur cette instance."
    $connection.Close()
    exit 0
}

Write-Log "Bases a sauvegarder ($($databases.Count)): $($databases -join ', ')"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$succeeded = New-Object System.Collections.Generic.List[string]
$failed = New-Object System.Collections.Generic.List[string]

foreach ($dbName in $databases) {
    $safeName = $dbName -replace '[\\/:*?"<>|]', '_'
    $backupFile = Join-Path $BackupPath "${safeName}_$timestamp.bak"

    Write-Log "Sauvegarde de '$dbName' -> $backupFile ..."

    $backupCommand = $connection.CreateCommand()
    $backupCommand.CommandTimeout = 0  # pas de limite : les backups peuvent etre longs

    $quotedDbName = "[" + ($dbName -replace ']', ']]') + "]"
    $quotedFile = $backupFile -replace "'", "''"

    $backupCommand.CommandText = @"
BACKUP DATABASE $quotedDbName
TO DISK = N'$quotedFile'
WITH INIT, STATS = 10, NAME = N'$dbName - Full Backup';
"@

    try {
        $backupCommand.ExecuteNonQuery() | Out-Null
        Write-Log "OK: '$dbName' sauvegardee."
        $succeeded.Add($dbName)
    }
    catch {
        Write-Log "Echec de la sauvegarde de '$dbName': $($_.Exception.Message)" "ERROR"
        $failed.Add($dbName)
    }
}

$connection.Close()

Write-Log "----- Resume -----"
Write-Log "Reussies ($($succeeded.Count)): $($succeeded -join ', ')"
if ($failed.Count -gt 0) {
    Write-Log "Echouees ($($failed.Count)): $($failed -join ', ')" "ERROR"
    exit 1
}

exit 0
