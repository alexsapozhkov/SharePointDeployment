# SharePoint Deployment

Deployment script for SharePoint environments

## Prerequisites

Open Windows PowerShell (not pwsh 7.1)console as administrator and run

```powershell
.\InstallPrerequisites.ps1
```

## Running in PowerShell

Open Windows PowerShell (not pwsh 7.1)console as administrator and run

```powershell
Connect-AzAccount
# Additionally use Select-AzSubscription for specifying a subscription to use
# Automation: Configure telemetry opt-in or opt-out
$env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'true';

Add-LabAzureSubscription -DefaultLocationName "West Europe";
Install-Module -Name AutomatedLab -Force -SkipPublisherCheck -AllowClobber -RequiredVersion 5.41.0
.\DeploySharePointEnvironment.ps1 -Topology SmallNonHAMinrole -ProvisioningLevel Binaries;
```

.\DeploySharePointEnvironment.ps1 -Topology SmallNonHAMinrole -ProvisioningLevel Binaries -AdminPassword Somepass1 -SPDC1Name swazspdc00 -SPDC1Size Standard_B2s -SPDB1Name swazspdb00 -SPDB1Size Standard_D2s_v3 -SPFE1Name swazspfe00 -SPFE1Size Standard_D2s_v3 -SPBE1Name swazspbe00 -SPBE1Size Standard_D2s_v3 -LabName SharePointDscDev35
