Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
Install-Module -Name Az -Force -AllowClobber
Install-Module -Name AutomatedLab -Force -SkipPublisherCheck -AllowClobber -RequiredVersion 5.40.0
