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

# Copy all required ISO files to "$labsources\ISOs" # $labSources is a dynamic variable and will point to lab sources

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

# Add virtual network
# Add-LabVirtualNetworkDefinition -Name "$($LabName)VNet" -AddressSpace 192.168.123.1/24

# Add domain details
Add-LabDomainDefinition -Name $DomainName -AdminUser Install -AdminPassword $AdminPassword

# Set Install credentials
Set-LabInstallationCredential -Username Install -Password $AdminPassword

#Get-LabAvailableOperatingSystem -Azure -Location $AzureDefaultLocation
#Get-LabAzureLocation
#Get-LabAzureAvailableRoleSize -Location 'West Europe'

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)'
}

# Syncing local LabSources with Azure
# Sync-LabAzureLabSources -SkipIsos

# Adding ISO Images to LabSources
#Add-LabIsoImageDefinition -Name SQLServer2019 -Path $labSources\ISOs\en_sql_server_2019_standard_x64_dvd_814b57aa.iso
#Add-LabIsoImageDefinition -Name SharePoint2019 -Path $labSources\ISOs\en_sharepoint_server_2019_x64_dvd_68e34c9e.iso

# Adding Post Install Activities
$dcPostInstallActivity = @()
$dcPostInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$dcPostInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'PrepareSPDomain.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareSPDomain

# Grabbing role details
$sqlRole = Get-LabMachineRoleDefinition -Role SQLServer2019 -Properties @{ Collation = "Latin1_General_CI_AS_KS_WS"; Features = 'SQL,Tools'}

# Adding Lab VMs
$azureProperties = $null;
if ($SPDC1Size) {$azureProperties = @{RoleSize = $SPDC1Size}}
Add-LabMachineDefinition -Name $SPDC1Name -Roles RootDC -PostInstallationActivity $dcPostInstallActivity -AzureProperties $azureProperties # Domain Controller
$azureProperties = $null;
if ($SPDB1Size) {$azureProperties = @{RoleSize = $SPDB1Size}}
Add-LabMachineDefinition -Name $SPDB1Name -Roles $sqlRole -AzureProperties $azureProperties # SQL Server
#SHAREPOINT ROLE CURRENTLY NOT WORKING# Add-LabMachineDefinition -Name SPFE1 -Roles SharePoint2019 # SharePoint Front End
#SHAREPOINT ROLE CURRENTLY NOT WORKING# Add-LabMachineDefinition -Name SPBE1 -Roles SharePoint2019 # SharePoint Application
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