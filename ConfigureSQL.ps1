Configuration ConfigureSQL
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SqlServiceAccount
    )
    # Import the module that defines custom resources
    Import-DscResource -Module SQLServerDsc

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.NodeName
    {
        SqlServiceAccount 'SetServiceAccount_User'
        {
            ServerName     = 'spdb1'
            InstanceName   = 'MSSQLSERVER'
            ServiceType    = 'DatabaseEngine'
            ServiceAccount = $SqlServiceAccount
            RestartService = $true
        }

        SqlMaxDop 'Set_SqlMaxDop_ToOne'
        {
            ServerName           = 'spdb1'
            InstanceName         = 'MSSQLSERVER'
            Ensure               = 'Present'
            MaxDop               = 1
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlTraceFlag 'Set_SqlTraceFlags'
        {
            ServerName           = 'spdb1'
            InstanceName         = 'MSSQLSERVER'
            TraceFlagsToInclude  = 1117
            RestartService       = $true
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabaseDefaultLocation 'Set_SqlDatabaseDefaultDirectory_Data'
        {
            ServerName              = 'spdb1'
            InstanceName            = 'MSSQLSERVER'
            ProcessOnlyOnActiveNode = $true
            Type                    = 'Data'
            Path                    = 'C:\Program Files\Microsoft SQL Server'
            PsDscRunAsCredential    = $SqlAdministratorCredential
        }

        SqlDatabaseDefaultLocation 'Set_SqlDatabaseDefaultDirectory_Log'
        {
            ServerName              = 'spdb1'
            InstanceName            = 'MSSQLSERVER'
            ProcessOnlyOnActiveNode = $true
            Type                    = 'Log'
            Path                    = 'C:\Program Files\Microsoft SQL Server'
            PsDscRunAsCredential    = $SqlAdministratorCredential
        }

        SqlDatabaseDefaultLocation 'Set_SqlDatabaseDefaultDirectory_Backup'
        {
            ServerName              = 'spdb1'
            InstanceName            = 'MSSQLSERVER'
            ProcessOnlyOnActiveNode = $true
            Type                    = 'Backup'
            Path                    = 'C:\Program Files\Microsoft SQL Server'
            PsDscRunAsCredential    = $SqlAdministratorCredential
        }

        SqlLogin 'Add_SetupAccountAsLogin'
        {
            ServerName           = 'spdb1'
            InstanceName         = 'MSSQLSERVER'
            Ensure               = 'Present'
            Name                 = 'CONTOSO\sa_setup'
            LoginType            = 'WindowsUser'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlRole 'Add_SetupToDBCreator'
        {
            ServerName           = 'spdb1'
            InstanceName         = 'MSSQLSERVER'
            Ensure               = 'Present'
            ServerRoleName       = 'dbcreator'
            MembersToInclude     = 'CONTOSO\sa_setup'
            DependsOn            = '[SqlLogin]Add_SetupAccountAsLogin'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlRole 'Add_SetupToSecurityAdmin'
        {
            ServerName           = 'spdb1'
            InstanceName         = 'MSSQLSERVER'
            Ensure               = 'Present'
            ServerRoleName       = 'securityadmin'
            MembersToInclude     = 'CONTOSO\sa_setup'
            DependsOn            = '[SqlLogin]Add_SetupAccountAsLogin'
            PsDscRunAsCredential = $SqlAdministratorCredential
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
            NodeName           = "SPDB1"
            PsDscAllowPlainTextPassword = $true
        }
    )
}

if ($null -eq (Get-Lab -ErrorAction SilentlyContinue))
{
    Import-Lab -Name SPDev
}

$server = Get-LabVM -ComputerName SPDB1
$installAccount = Get-Credential 'contoso\Install'

$username = 'contoso\sa_sql'
$password = ConvertTo-SecureString "Password1" -AsPlainText -Force
$sqlAccount = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)

cd $PSScriptRoot

$null = ConfigureSQL -ConfigurationData $ConfigurationData -SqlAdministratorCredential $installAccount -SqlServiceAccount $sqlAccount

$module = Get-Module SQLServerDsc -ListAvailable | Sort-Object -Property Version | Select-Object -First 1
if ($null -eq $module)
{
    $module = Install-Module SQLServerDsc -PassThru
}
Send-ModuleToPSSession -Module $module -Session (New-LabPSSession -ComputerName $server.Name)

$cimSession = New-LabCimSession -ComputerName $server.Name -UseLocalCredential

if (Test-Path -Path ".\ConfigureSQL\$($cimSession.ComputerName).mof")
{
    Remove-Item -Path ".\ConfigureSQL\$($cimSession.ComputerName).mof" -Confirm:$false
}
Rename-Item -Path ".\ConfigureSQL\$($server.Name).mof" -NewName "$($cimSession.ComputerName).mof"

Start-DscConfiguration -Path .\ConfigureSQL -CimSession $cimSession -Wait -Verbose

#### Invoke-LabDscConfiguration does not support parameters in configurations yet
#Invoke-LabDscConfiguration -Configuration (Get-Command -Name ConfigureSQL) -ConfigurationData $ConfigurationData -ComputerName SPDB1 -Wait -Force
