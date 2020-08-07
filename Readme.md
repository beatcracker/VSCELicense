# 📜 VSCELicense

- [Details](#details)
- [Usage](#usage)
- [Examples](#examples)
  - [Get Visual Studio Community Edition license expiration date](#get-visual-studio-community-edition-license-expiration-date)
  - [Set Visual Studio Community Edition license expiration date](#set-visual-studio-community-edition-license-expiration-date)
    - [Set license expiration date to 31 day from now](#set-license-expiration-date-to-31-days-from-nowy)
    - [Set license expiration date to 10 days from now](#set-license-expiration-date-to-10-days-from-now)
    - [Set license expiration date to current date](#set-license-expiration-date-to-current-date)
- [Changelog](#changelog)

## Details

PowerShell module to get and set Visual Studio Community Edition license expiration date in the registry. Visual Studio 2015, 2017 and 2019 are supported.

Based on [Dmitrii](https://stackoverflow.com/users/10046552/dmitrii)'s answer to this question: [Visual Studio Community 2017 is a 30 day trial?](https://stackoverflow.com/questions/43390466/visual-studio-community-2017-is-a-30-day-trial/51570570#51570570)

## Usage

1. Download/clone this repository
2. Run PowerShell.exe as Administrator
3. Import module:

    Assuming that you cloned/downloaded this repo to `C:\VSCELicense`

   ```pwsh
   Import-Module -Name 'C:\VSCELicense\VSCELicense.psd1'
   ```

    If you get `execution of scripts is disabled on this system` message, you can temporarily override PowerShell execution policy by running

   ```pwsh
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   ```

    See PowerShell documentation for more details:

    - [Set-ExecutionPolicy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy)
    - [About Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

## Examples

### Get Visual Studio Community Edition license expiration date

All supported versions of Visual Studio.

```pwsh
Get-VSCELicenseExpirationDate
```

One specific version of Visual Studio.

```pwsh
Get-VSCELicenseExpirationDate -Version 2017
```

Multiple versions of Visual Studio.

```pwsh
Get-VSCELicenseExpirationDate -Version 2019, 2017
```

### Set Visual Studio Community Edition license expiration date

⚡ Writing to the Visual Studio license registry key requires elevated permissions. Run PowerShell as administrator for examples to work.

#### Set license expiration date to 31 day from now

All supported versions of Visual Studio.

```pwsh
Set-VSCELicenseExpirationDate
```

One specific version of Visual Studio.

```pwsh
Set-VSCELicenseExpirationDate -Version 2017
```

Multiple versions of Visual Studio.

```pwsh
Set-VSCELicenseExpirationDate -Version 2019
```

#### Set license expiration date to 10 days from now

All supported versions of Visual Studio.

```pwsh
Set-VSCELicenseExpirationDate -AddDays 10
```

One specific version of Visual Studio.

```pwsh
Set-VSCELicenseExpirationDate -Version 2017 -AddDays 10
```

Multiple versions of Visual Studio.

```pwsh
Set-VSCELicenseExpirationDate -Version 2019, 2017 -AddDays 10
```

#### Set license expiration date to current date

⚡ This will immediately expire your license and you wouldn't be able to use Visual Studio.

All supported versions of Visual Studio.

```pwsh
Set-VSCELicenseExpirationDate -AddDays 0
```

One specific version of Visual Studio.

```pwsh
Set-VSCELicenseExpirationDate -Version 2017 -AddDays 0
```

Multiple versions of Visual Studio.

```pwsh
Set-VSCELicenseExpirationDate -Version 2019 -AddDays 0
```

### Changelog

- 0.0.8 - Make it easier to use by not requiring to specify Visual Studio version
- 0.0.7 - Added 2015 support ([@GDI123](https://github.com/GDI123))
- 0.0.6 - Load `System.Security` assembly if module was imported without manifest
- 0.0.5 - Duh, actually set `PowerShellVersion = '3.0'` in manifest
- 0.0.4 - Support downlevel PowerShell versions, starting from `3.0`
- 0.0.3 - Fixed manifest to avoid execution errors under fresh PowerShell environments ([@1Dimitri](https://github.com/1Dimitri))
- 0.0.2 - Added 2019 support
- 0.0.1 - Initial commit, 2017 support
