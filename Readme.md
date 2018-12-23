# VSCELicense

## Details

PowerShell module to get and set Visual Studio Community Edition license expiration date in the registry. Only Visual Studio 2017 is supported for now.


Based on [Dmitrii](https://stackoverflow.com/users/10046552/dmitrii)'s answer to this question: [Visual Studio Community 2017 is a 30 day trial?](https://stackoverflow.com/questions/43390466/visual-studio-community-2017-is-a-30-day-trial/51570570#51570570)

## Usage

1. Download/clone this repository
2. Import module: `Import-Module -Name X:\PATH\TO\REPOSITORY`

## Examples

### Get Visual Studio Community Edition license expiration date

```posh
Get-VSCELicenseExpirationDate -Version VS2017
```

### Set Visual Studio Community Edition license expiration date

#### Set license expiration date to current date + 31 day

```posh
Set-VSCELicenseExpirationDate -Version VS2017
```

#### Set license expiration date to current date + 10 days

```posh
Set-VSCELicenseExpirationDate -Version VS2017 -AddDays 10
```

#### Set license expiration date to current date

This will immediately expire your license and you woudln't be able to use Visual Studio.

```posh
Set-VSCELicenseExpirationDate -Version VS2017 -AddDays
```