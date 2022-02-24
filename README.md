# SharePoint Deployment

Deployment script for SharePoint environments

## Prerequisites

Open Windows PowerShell (not pwsh 7.1)console as administrator and run

```powershell
# requires -runAs

####### FUNCTIONS #######
function Ensure-Module
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $moduleInGallery = Find-Module -Name $Name
    $moduleOnServer = Get-InstalledModule $Name

    # If AutomatedLab doesn't exist or version is lower than the version in the PS Gallery
    if ($null -eq $moduleOnServer -or $moduleInGallery.Version -lt $moduleOnServer.Version)
    {
        Install-Module -Name $Name -Force
    }
}

####### START SCRIPT #######

Ensure-Module -Name Az
Ensure-Module -Name AutomatedLab
```

## Running in PowerShell

Open Windows PowerShell (not pwsh 7.1)console as administrator and run

```powershell
Connect-AzAccount
# Additionally use Select-AzSubscription for specifying a subscription to use
# Automation: Configure telemetry opt-in or opt-out
$env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'true';
.\DeploySharePointEnvironment.ps1 -Topology SmallNonHAMinrole -ProvisioningLevel Binaries;
```

.\DeploySharePointEnvironment.ps1 -Topology SmallNonHAMinrole -ProvisioningLevel Binaries -LabName SharePointDscDev33 -AdminPassword Somepass1 -SPDC1Name swazspdc00 -SPDC1Size Standard_B2s -SPDB1Name swazspdb00 -SPDB1Size Standard_D2s_v3 -SPFE1Name swazspfe00 -SPFE1Size Standard_D2s_v3 -SPBE1Name swazspbe00 -SPBE1Size Standard_D2s_v3
