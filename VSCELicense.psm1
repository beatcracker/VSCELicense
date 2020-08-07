#region Constants

New-Variable -Name VSCELicenseMap -Value @{
    '2015' = 'Licenses\4D8CFBCB-2F6A-4AD2-BABF-10E28F6F2C8F\07078'
    '2017' = 'Licenses\5C505A59-E312-4B89-9508-E162F8150517\08878'
    '2019' = 'Licenses\41717607-F34E-432C-A138-A3CFD7E25CDA\09278'
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

        if ($null -ne $LicenseKey) {
            $LicenseKey
        }
    }
}

#endregion


#region External functions

<#
.Synopsis
    Get Visual Studio Community Edition license expiration date

.Parameter Version
    String array. One ore more of the suported Visual Studio Community Edition versions.
    Default: '2015', '2017', '2019'

.Example
    Get-VSCELicenseExpirationDate -Version 2017

    Get expiration date for all suported versions of Visual Studio.

.Example
    Get-VSCELicenseExpirationDate -Version 2017

    Get expiration date for Visual Studio 2017.
#>
function Get-VSCELicenseExpirationDate {
    [CmdletBinding()]
    Param (
        [ValidateSet('2015', '2017', '2019')]
        [string[]]$Version = @('2015', '2017', '2019')
    )

    End {
        foreach ($v in $Version) {
            if ($LicenseKey = Open-HKCRSubKey -SubKey $VSCELicenseMap.$v) {

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

                [PSCustomObject]@{
                    Version        = $v
                    ExpirationDate = ConvertFrom-BinaryDate $LicenseBlob[-16..-11] -ErrorAction Stop
                }
            }
        }
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
    String array. One ore more of the suported Visual Studio Community Edition versions.
    Default: '2015', '2017', '2019'

.Parameter AddDays
    Int. Number of days to add. 31 is max allowed and default.

.Example
    Set-VSCELicenseExpirationDate

    Set license expiration date to current date + 31 day for all suported versions of Visual Studio.

.Example
    Set-VSCELicenseExpirationDate -Version 2019

    Set license expiration date to current date + 31 day for Visual Studio 2019 only.

.Example
    Set-VSCELicenseExpirationDate -AddDays 10

    Set license expiration date to current date + 10 days for all suported versions of Visual Studio.

.Example
    Set-VSCELicenseExpirationDate -Version 2019 -AddDays 0

    Set license expiration date to current date for Visual Studio 2019 only.
    This will immediately expire your license and you wouldn't be able to use Visual Studio 2019.
#>
function Set-VSCELicenseExpirationDate {
    [CmdletBinding()]
    Param (
        [ValidateSet('2015', '2017', '2019')]
        [string[]]$Version = @('2015', '2017', '2019'),

        [ValidateRange(0, 31)]
        [int]$AddDays = 31
    )

    End {
        foreach ($v in $Version) {
            if ($LicenseKey = Open-HKCRSubKey -SubKey $VSCELicenseMap.$v -ReadWrite) {

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

                [PSCustomObject]@{
                    Version        = $v
                    ExpirationDate = $NewExpirationDate
                }
            }
        }
    }
}

#endregion


#region Init

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