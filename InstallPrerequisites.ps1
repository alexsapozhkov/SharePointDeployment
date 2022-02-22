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
        Install-Module -Name $Name -Force -ErrorAction Ignore
    }
}

####### START SCRIPT #######

Ensure-Module -Name Az
Ensure-Module -Name AutomatedLab
