# VSCELicense

## Details

PowerShell module to get and set Visual Studio Community Edition license expiration date in the registry. Visual Studio 2017 and 2019 are supported.

Based on [Dmitrii](https://stackoverflow.com/users/10046552/dmitrii)'s answer to this question: [Visual Studio Community 2017 is a 30 day trial?](https://stackoverflow.com/questions/43390466/visual-studio-community-2017-is-a-30-day-trial/51570570#51570570)

## Usage

1. Download/clone this repository
2. Import module:

   ```posh
   Import-Module -Name X:\PATH\TO\VSCELicense
   ```
You may also get PowerShell execution restriction message. In such case use:

   '''posh
   Set-ExecutionPolicy Unrestricted -Scope Process
   '''
## Examples

### Get Visual Studio Community Edition license expiration date

```posh
Get-VSCELicenseExpirationDate -Version VS2015
```

```posh
Get-VSCELicenseExpirationDate -Version VS2017
```

```posh
Get-VSCELicenseExpirationDate -Version VS2019
```

### Set Visual Studio Community Edition license expiration date

Writing to the Visual Studio license registry key requires elevated permissions. Run PowerShell as administrator for examples to work.

#### Set license expiration date to current date + 31 day

```posh
Set-VSCELicenseExpirationDate -Version VS2015
```

```posh
Set-VSCELicenseExpirationDate -Version VS2017
```

```posh
Set-VSCELicenseExpirationDate -Version VS2019
```

#### Set license expiration date to current date + 10 days

```posh
Set-VSCELicenseExpirationDate -Version VS2015 -AddDays 10
```

```posh
Set-VSCELicenseExpirationDate -Version VS2017 -AddDays 10
```

```posh
Set-VSCELicenseExpirationDate -Version VS2019 -AddDays 10
```

#### Set license expiration date to current date

This will immediately expire your license and you wouldn't be able to use Visual Studio.

```posh
Set-VSCELicenseExpirationDate -Version VS2015 -AddDays 0
```

```posh
Set-VSCELicenseExpirationDate -Version VS2017 -AddDays 0
```

```posh
Set-VSCELicenseExpirationDate -Version VS2019 -AddDays 0
```

### Changelog

- 0.0.1 - Initial commit, VS2017 support
- 0.0.2 - Added VS2019 support
- 0.0.3 - Fixed manifest to avoid execution errors under fresh PowerShell environments ([@1Dimitri](https://github.com/1Dimitri))
- 0.0.4 - Support downlevel PowerShell versions, starting from `3.0`
- 0.0.5 - Duh, actually set `PowerShellVersion = '3.0'` in manifest
- 0.0.6 - Load `System.Security` assembly if module was imported without manifest
- 0.0.7 - Added VS2015 support ([@GDI123](https://github.com/GDI123))
