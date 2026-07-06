```powershell
# Avec authentification Windows (Username/Password vides)
.\scripts\Backup-AllDatabases.ps1 -ServerInstance "localhost,1433" -BackupPath "D:\Backups\SQL"

# Avec authentification SQL Server
.\scripts\Backup-AllDatabases.ps1 -ServerInstance "localhost\SQLEXPRESS" -Username "sa" -Password "Allures51" -BackupPath "c:\tmp"
```
