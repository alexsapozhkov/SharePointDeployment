
Configuration ConfigureSP
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SPAdministratorCredential
    )
    # Import the module that defines custom resources
    Import-DscResource -Module SharePointDsc

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.NodeName
    {
        $features = @("NET-WCF-Pipe-Activation45", "NET-WCF-HTTP-Activation45", "NET-WCF-TCP-Activation45", "Web-Server", "Web-WebServer", "Web-Common-Http", "Web-Static-Content", "Web-Default-Doc", "Web-Dir-Browsing", "Web-Http-Errors", "Web-App-Dev", "Web-Asp-Net45", "Web-Net-Ext45", "Web-ISAPI-Ext", "Web-ISAPI-Filter", "Web-Health", "Web-Http-Logging", "Web-Log-Libraries", "Web-Request-Monitor", "Web-Http-Tracing", "Web-Security", "Web-Basic-Auth", "Web-Windows-Auth", "Web-Filtering", "Web-Performance", "Web-Stat-Compression", "Web-Dyn-Compression", "WAS", "WAS-Process-Model", "WAS-Config-APIs", "Web-Mgmt-Tools")
        foreach ($feature in $features)
        {
            WindowsFeature $feature
            {
                Name   = $feature
                Ensure = 'Present'
            }
        }

        SPInstallPrereqs 'InstallPrerequisitesOnline'
        {
            IsSingleInstance = "Yes"
            InstallerPath    = "C:\SPInstall\Prerequisiteinstaller.exe"
            OnlineMode       = $true
        }

        SPInstall 'InstallBinaries'
        {
            IsSingleInstance = "Yes"
            BinaryDir        = "C:\SPInstall"
            ProductKey       = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
            DependsOn        = '[SPInstallPrereqs]InstallPrerequisitesOnline'
        }
    }
}

# Content of configuration data file (e.g. ConfigurationData.psd1) could be:
# Hashtable to define the environmental data
$ConfigurationData = @{
    # Node specific data
    AllNodes = @(
        # All the WebServer has following identical information
        @{
            NodeName = "SPBE1"
        },
        @{
            NodeName = "SPFE1"
        }
    )
}

if ($null -eq (Get-Lab -ErrorAction SilentlyContinue))
{
    Import-Lab -Name SPDev
}

$servers = Get-LabVM -ComputerName SPFE1, SPBE1
$installAccount = Get-Credential 'contoso\Install'

cd $PSScriptRoot

$null = ConfigureSP -ConfigurationData $ConfigurationData -SPAdministratorCredential $installAccount

$module = Get-Module SharePointDsc -ListAvailable | Sort-Object -Property Version | Select-Object -First 1
if ($null -eq $module)
{
    $module = Install-Module SharePointDsc -PassThru
}
Send-ModuleToPSSession -Module $module -Session (New-LabPSSession -ComputerName $servers.Name)

foreach ($computer in $servers)
{
    $cimSession = New-LabCimSession -ComputerName $computer.Name -UseLocalCredential

    if (Test-Path -Path ".\ConfigureSP\$($cimSession.ComputerName).mof")
    {
        Remove-Item -Path ".\ConfigureSP\$($cimSession.ComputerName).mof" -Confirm:$false
    }
    Rename-Item -Path ".\ConfigureSP\$($computer.Name).mof" -NewName "$($cimSession.ComputerName).mof"

    Start-DscConfiguration -Path .\ConfigureSP -CimSession $cimSession -Wait -Verbose
}

#### Invoke-LabDscConfiguration does not support parameters in configurations yet
#Invoke-LabDscConfiguration -Configuration (Get-Command -Name ConfigureSP) -ConfigurationData $ConfigurationData -ComputerName SPBE1,SPFE1 -Wait -Force
