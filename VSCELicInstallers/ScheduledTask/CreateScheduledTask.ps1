$PSCommand = @"
Import-Module VSCELicense;

@('VS2019','VS2017') | ForEach-Object {
    try {
   
        Get-VSCELicenseExpirationDate -Version `$_;
        Set-VSCELicenseExpirationDate -Version `$_;       
    } catch {
        Write-Verbose "`$_ seems not be installed"
    }
}
"@

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-Command "'+$PSCommand+'"')

$Triggers = New-ScheduledTaskTrigger -Daily  -At 1am
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
$Task =  New-ScheduledTask -Action $Action -Principal $Principal -Trigger $Triggers -Settings $Settings
Register-ScheduledTask 'VisualStudio\ResetLicense' -InputObject $Task