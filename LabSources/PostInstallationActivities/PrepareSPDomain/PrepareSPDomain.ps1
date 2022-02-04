Import-Module -Name ActiveDirectory

if (-not (Get-Command -Name Get-ADReplicationSite -ErrorAction SilentlyContinue))
{
	Write-ScreenInfo 'The script "PrepareRootDomain.ps1" script runs only if the ADReplication cmdlets are available' -Type Warning
	return
}

$password = "Password1"
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force

#Create standard accounts
$workOu = New-ADOrganizationalUnit -Name SharePoint -PassThru -ProtectedFromAccidentalDeletion:$false

$saSQL = New-ADUser -Name sa_sql -AccountPassword $securePassword -Path $workOu -Enabled $true -PassThru
$saSetup = New-ADUser -Name sa_setup -AccountPassword $securePassword -Path $workOu -Enabled $true -PassThru

