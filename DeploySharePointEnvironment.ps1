[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)][ValidateSet("SmallNonHAMinrole")]
    [String]$Topology,
    [Parameter(Mandatory = $true)][ValidateSet("Binaries")]
    [String]$ProvisioningLevel,
    [Parameter(Mandatory = $false)][ValidateSet("SE")]
    [String]$SharePointVersion = "SE",
    [Parameter(Mandatory = $false)]
    [String]$LabName = 'SPDev',
    [Parameter(Mandatory = $false)]
    [String]$DomainName = 'contoso.com',
    [Parameter(Mandatory = $false)]
    [String]$VitualizationEngine = 'Azure',
    [Parameter(Mandatory = $false)]
    [String]$AzureDefaultLocation = 'West Europe',
    [Parameter(Mandatory = $false)]
    [String]$AdminPassword = 'MySecretPassword!',
    [Parameter(Mandatory = $false)]
    [String]$SPDC1Name = 'SPDC1',
    [Parameter(Mandatory = $false)]
    [String]$SPDC1Size,
    [Parameter(Mandatory = $false)]
    [String]$SPDB1Name = 'SPDB1',
    [Parameter(Mandatory = $false)]
    [String]$SPDB1Size,
    [Parameter(Mandatory = $false)]
    [String]$SPFE1Name = 'SPFE1',
    [Parameter(Mandatory = $false)]
    [String]$SPFE1Size,
    [Parameter(Mandatory = $false)]
    [String]$SPBE1Name = 'SPBE1',
    [Parameter(Mandatory = $false)]
    [String]$SPBE1Size
)

# requires -runAs

if ((Test-Path -Path 'C:\LabSources') -eq $false)
{
    New-LabSourcesFolder -Drive C -Force
}

# Create new AL Lab definition
New-LabDefinition -Name $LabName -DefaultVirtualizationEngine $VitualizationEngine

if ($VitualizationEngine -eq 'Azure')
{
    # Check if logged into Azure, else logon
    $context = Get-AzContext
    if ($null -eq $context.Account)
    {
        $null = Login-AzAccount
    }

    # Add current Azure subscription to new lab definition
    Add-LabAzureSubscription -DefaultLocationName $AzureDefaultLocation
}

# Add domain details
Add-LabDomainDefinition -Name $DomainName -AdminUser Install -AdminPassword $AdminPassword

# Set Install credentials
Set-LabInstallationCredential -Username Install -Password $AdminPassword


$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)'
}

# Adding Post Install Activities
$dcPostInstallActivity = @()
$dcPostInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$dcPostInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'PrepareSPDomain.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareSPDomain

# Adding Lab VMs
$azureProperties = $null;
if ($SPDC1Size) {$azureProperties = @{RoleSize = $SPDC1Size}}
Add-LabMachineDefinition -Name $SPDC1Name -Roles RootDC -PostInstallationActivity $dcPostInstallActivity -AzureProperties $azureProperties # Domain Controller
$azureProperties = $null;
if ($SPDB1Size) {$azureProperties = @{RoleSize = $SPDB1Size}}
Add-LabMachineDefinition -Name $SPDB1Name -Roles SQLServer2016 -AzureProperties $azureProperties # SQL Server
$azureProperties = $null;
if ($SPFE1Size) {$azureProperties = @{RoleSize = $SPFE1Size}}
Add-LabMachineDefinition -Name $SPFE1Name -AzureProperties $azureProperties # SharePoint Front End
$azureProperties = $null;
if ($SPBE1Size) {$azureProperties = @{RoleSize = $SPBE1Size}}
Add-LabMachineDefinition -Name $SPBE1Name -AzureProperties $azureProperties # SharePoint Application

# Start deployment
Install-Lab

Show-LabDeploymentSummary

# Mount ISO to servers
#$location = Mount-LabIsoImage -ComputerName SPFE1 -IsoPath $labSources\ISOs\en_sharepoint_server_2019_x64_dvd_68e34c9e.iso -PassThru
#Dismount-LabIsoImage -ComputerName SPFE1