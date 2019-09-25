#region Constants

New-Variable -Name VSCELicenseMap -Value @{
    'VS2017' = 'Licenses\5C505A59-E312-4B89-9508-E162F8150517\08878'
    'VS2019' = 'Licenses\41717607-F34E-432C-A138-A3CFD7E25CDA\09278'
} -Option Constant

#endregion


#region Internal functions

<#
.Synopsis
    Test if PowerShell is running as elevated process
#>
function Test-Elevation {
    [bool](
        (
            [System.Security.Principal.WindowsIdentity]::GetCurrent()
        ).Groups -contains 'S-1-5-32-544'
    )
}


<#
.Synopsis
    Converts VS CE binary date format to [datetime]
#>
function ConvertFrom-BinaryDate {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateCount(6, 6)]
        [uint16[]]$InputObject
    )

    End {
        Get-Date -Year (
            [System.BitConverter]::ToInt16(
                $InputObject[0..1],
                0
            )
        ) -Month (
            [System.BitConverter]::ToInt16(
                $InputObject[2..3],
                0
            )
        ) -Day (
            [System.BitConverter]::ToInt16(
                $InputObject[4..6],
                0
            )
        ) -Hour 0 -Minute 0 -Second 0
    }
}


<#
.Synopsis
    Convert [datetime] to VS CE binary date format
#>
function ConvertTo-BinaryDate {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [datetime]$Date
    )

    Process {
        $Date.Year, $Date.Month, $Date.Day | ForEach-Object {
            [System.BitConverter]::GetBytes([uint16]$_)
        }
    }
}


<#
.Synopsis
    Open registry subkey in HKCR for read(write) access
#>
Function Open-HKCRSubKey {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubKey,

        [switch]$ReadWrite
    )

    Begin {
        if ($ReadWrite -and -not (Test-Elevation)) {
            throw 'This action requires elevated permissions. Run PowerShell as Administrator.'
        }
    }

    Process {
        try {
            $HKCR = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
                [Microsoft.Win32.RegistryHive]::ClassesRoot,
                [Microsoft.Win32.RegistryView]::Default
            )

            $LicenseKey = $HKCR.OpenSubKey(
                $SubKey,
                $ReadWrite
            )
        }
        catch {
            throw $_
        }
        finally {
            $HKCR.Dispose()
        }

        if (-not $LicenseKey.ValueCount) {
            throw "Registry key not found: HKEY_CLASSES_ROOT\$SubKey"
        }

        $LicenseKey
    }
}

#endregion

#region External functions

<#
.Synopsis
    Get Visual Studio Community Edition license expiration date

.Parameter Version
    String. One of the suported Visual Studio Community Edition versions. Default is VS2017.

.Example
    Get-VSCELicenseExpirationDate -Version VS2017
#>
function Get-VSCELicenseExpirationDate {
    [CmdletBinding()]
    Param (
        [ValidateSet('VS2017', 'VS2019')]
        [string]$Version = 'VS2017'
    )

    End {
        $LicenseKey = Open-HKCRSubKey -SubKey $VSCELicenseMap.$Version

        try {
            $LicenseBlob = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $LicenseKey.GetValue($null),
                $null,
                [System.Security.Cryptography.DataProtectionScope]::LocalMachine
            )
        }
        catch {
            throw $_
        }
        finally {
            $LicenseKey.Dispose()
        }

        ConvertFrom-BinaryDate $LicenseBlob[-16..-11] -ErrorAction Stop
    }
}


<#
.Synopsis
    Set Visual Studio Community Edition license expiration date

.Description
    Set Visual Studio Community Edition license expiration date.
    Will add 31 day from current date by default.
    This is max allowed number of days, otherwise your license will be deemed invalid.

.Parameter Version
    String. One of the suported Visual Studio Community Edition versions. Default is VS2017.

.Parameter AddDays
    Int. Number of days to add. 31 is max allowed and default.

.Example
    Set-VSCELicenseExpirationDate -Version VS2017

    Set license expiration date to current date + 31 day (Visual Studio 2017)

.Example
    Set-VSCELicenseExpirationDate -Version VS2019

    Set license expiration date to current date + 31 day  (Visual Studio 2019)

.Example
    Set-VSCELicenseExpirationDate -Version VS2019 -AddDays 10

    Set license expiration date to current date + 10 days

.Example
    Set-VSCELicenseExpirationDate -Version VS2019 -AddDays 0

    Set license expiration date to current date.
    This will immediately expire your license and you wouldn't be able to use Visual Studio.
#>
function Set-VSCELicenseExpirationDate {
    [CmdletBinding()]
    Param (
        [ValidateSet('VS2017', 'VS2019')]
        [string]$Version = 'VS2017',

        [ValidateRange(0, 31)]
        [int]$AddDays = 31
    )

    End {
        $LicenseKey = Open-HKCRSubKey -SubKey $VSCELicenseMap.$Version -ReadWrite

        try {
            $LicenseBlob = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $LicenseKey.GetValue($null),
                $null,
                [System.Security.Cryptography.DataProtectionScope]::LocalMachine
            )

            $NewExpirationDate = [datetime]::Today.AddDays($AddDays)

            $LicenseKey.SetValue(
                $null,
                [System.Security.Cryptography.ProtectedData]::Protect(
                    @(
                        $LicenseBlob[ - $LicenseBlob.Count..-17]
                        $NewExpirationDate | ConvertTo-BinaryDate -ErrorAction Stop
                        $LicenseBlob[-10..-1]
                    ),
                    $null,
                    [System.Security.Cryptography.DataProtectionScope]::LocalMachine
                ),
                [Microsoft.Win32.RegistryValueKind]::Binary
            )
        }
        catch {
            throw $_
        }
        finally {
            $LicenseKey.Dispose()
        }

        $NewExpirationDate
    }
}

#endregion

#region Startup

if (-not ([System.Management.Automation.PSTypeName]'System.Security.Cryptography.ProtectedData').Type) {
    $ModulePath = $Script:MyInvocation.MyCommand.Path
    $ModuleFolder = [System.IO.Path]::GetDirectoryName($ModulePath)
    $ModuleManifest = Join-Path $ModuleFolder ([System.IO.Path]::GetFileNameWithoutExtension($ModulePath) + '.psd1')

    @(
        "Loading 'System.Security' assembly."
        'To avoid this message, import module using manifest or folder name w/o trailing slash:'
        "Import-Module -Name '$ModuleManifest'"
        "Import-Module -Name '$ModuleFolder'"
    ) -join [System.Environment]::NewLine | Write-Warning

    Add-Type -AssemblyName 'System.Security' -ErrorAction Stop
}

#endregion