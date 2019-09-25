@{
    RootModule           = 'VSCELicense.psm1'
    ModuleVersion        = '0.0.6'
    GUID                 = 'a99bf6dc-41a5-4305-9113-db6d94fc5147'
    Author               = 'beatcracker'
    CompanyName          = 'N/A'
    Copyright            = '2019'
    Description          = 'Get and set Visual Studio Community Edition license expiration date in the registry. Visual Studio 2017 and 2019 are supported. Based on this answer: https://stackoverflow.com/questions/43390466/visual-studio-community-2017-is-a-30-day-trial/51570570#51570570'
    PowerShellVersion    = '3.0'
    RequiredAssemblies   = @('System.Security')
    FunctionsToExport    = @(
        'Set-VSCELicenseExpirationDate'
        'Get-VSCELicenseExpirationDate'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
}