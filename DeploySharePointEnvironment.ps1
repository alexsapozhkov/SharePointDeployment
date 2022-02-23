# requires -runAs

# Script variables - Now hardcoded, must be parameterized
$labName = 'SPDev'
$domainName = 'contoso.com'
$vitualizationEngine = 'Azure'
$azureDefaultLocation = 'West Europe'
$password = 'MySecretPassword!'

# Automation: Configure telemetry opt-in or opt-out
[Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'yes', 'Machine')
$env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'true'
Import-Module AutomatedLab

if ((Test-Path -Path 'C:\LabSources') -eq $false)
{
    New-LabSourcesFolder -Drive C -Force
}

# Copy all required ISO files to
"$labsources\ISOs" # $labSources is a dynamic variable and will point to lab sources

# Create new AL Lab definition
New-LabDefinition -Name $labname -DefaultVirtualizationEngine $vitualizationEngine

if ($vitualizationEngine -eq 'Azure')
{
    # Check if logged into Azure, else logon
    $context = Get-AzContext
    if ($null -eq $context.Account)
    {
        $null = Login-AzAccount
    }

    # Add current Azure subscription to new lab definition
    Add-LabAzureSubscription -DefaultLocationName $azureDefaultLocation
}

# Add virtual network
Add-LabVirtualNetworkDefinition -Name "$($labname)VNet" -AddressSpace 192.168.123.1/24

# Add domain details
Add-LabDomainDefinition -Name $domainName -AdminUser Install -AdminPassword $password

# Set Install credentials
Set-LabInstallationCredential -Username Install -Password $password

#Get-LabAvailableOperatingSystem -Azure -Location $azureDefaultLocation
#Get-LabAzureLocation
#Get-LabAzureAvailableRoleSize -Location 'West Europe'

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2022 Datacenter (Desktop Experience)'
}

# Syncing local LabSources with Azure
Sync-LabAzureLabSources -SkipIsos

# Adding ISO Images to LabSources
Add-LabIsoImageDefinition -Name SQLServer2019 -Path $labSources\ISOs\en_sql_server_2019_standard_x64_dvd_814b57aa.iso
Add-LabIsoImageDefinition -Name SharePoint2019 -Path $labSources\ISOs\en_sharepoint_server_2019_x64_dvd_68e34c9e.iso

# Adding Post Install Activities
$dcPostInstallActivity = @()
$dcPostInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$dcPostInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'PrepareSPDomain.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareSPDomain

# Grabbing role details
$sqlRole = Get-LabMachineRoleDefinition -Role SQLServer2019 -Properties @{ Collation = "Latin1_General_CI_AS_KS_WS"; Features = 'SQL,Tools'}

# Adding Lab VMs
Add-LabMachineDefinition -Name SPDC1 -Roles RootDC -PostInstallationActivity $dcPostInstallActivity # Domain Controller
Add-LabMachineDefinition -Name SPDB1 -Roles $sqlRole # SQL Server
#SHAREPOINT ROLE CURRENTLY NOT WORKING# Add-LabMachineDefinition -Name SPFE1 -Roles SharePoint2019 # SharePoint Front End
#SHAREPOINT ROLE CURRENTLY NOT WORKING# Add-LabMachineDefinition -Name SPBE1 -Roles SharePoint2019 # SharePoint Application
Add-LabMachineDefinition -Name SPFE1 # SharePoint Front End
Add-LabMachineDefinition -Name SPBE1 # SharePoint Application

# Start deployment
Install-Lab

Show-LabDeploymentSummary

# Mount ISO to servers
#$location = Mount-LabIsoImage -ComputerName SPFE1 -IsoPath $labSources\ISOs\en_sharepoint_server_2019_x64_dvd_68e34c9e.iso -PassThru
#Dismount-LabIsoImage -ComputerName SPFE1