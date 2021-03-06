<#

.SYNOPSIS

Deploys the Information Architecture specified.

.DESCRIPTION

The DeploySP.ps1 script accepts an array of Function names which correspond with the type
of SharePoint artefacts to be deployed. Each function expects a corresponding CSV file with the same name
in the same folder (using $PSScriptRoot).
This script relies on the OfficeDev PnP-PowerShell cmdlets (https://github.com/OfficeDev/PnP-PowerShell)
which must be installed before use:
Install-Module SharePointPnPPowerShellOnline
OR
Install-Module SharePointPnPPowerShell2016
OR
Install-Module SharePointPnPPowerShell2013

.PARAMETER TargetSiteUrl 

The URL of the target SharePoint Online site collection.

.PARAMETER CredentialLabel

The name of the generic credential (stored in Windows Credential Manager) to use to connect to the site.

.PARAMETER CSVFolderPath

The absolute path to a local folder containing the CSVs to process (must have matching named functions in FunctionsToRun).

.PARAMETER FunctionsToRun

A comma-separated array of functions to execute (must have matching CSVs in CSVFolderPath).

.EXAMPLE

.\DeploySP.ps1 -TargetSiteUrl https://contoso.sharepoint.com/sites/target -CredentialLabel contoso -CSVFolderPath "C:\Projects\Project1\CSVs" -FunctionsToRun ContentTypes,SiteColumns

.NOTES


#>

Param(
	[string]$TargetSiteUrl,
	[string]$CredentialLabel,
	[string]$CSVFolderPath,
	[string[]]$FunctionsToRun
)
	$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
	$global:creds = $CredentialLabel
	Set-Location $scriptPath
	Try {
		if($CredentialLabel -eq "web") {
			Connect-PnPOnline -Url $TargetSiteUrl -UseWebLogin
		} else {
			Connect-PnPOnline -Url $TargetSiteUrl -Credentials $CredentialLabel
		}
		Write-Host "## Successfully connected to $TargetSiteUrl ##" -ForegroundColor Green
	} Catch {
		Write-Host "!! Failed to connect to $TargetSiteUrl - please check credentials !!" -ForegroundColor Red
		Exit
	}
	if($FunctionsToRun.Contains("UnifiedGroups") -or $FunctionsToRun.Contains("RemoveUnifiedGroups")) {
		Try {
			Connect-PnPMicrosoftGraph -Scopes Group.ReadWrite.All
			Write-Host "## Successfully connected to Microsoft Graph ##" -ForegroundColor Green
		} Catch {
			Write-Host "!! Failed to connect to Microsoft Graph !!" -ForegroundColor Red
			Exit
		}
	}
    #Load up the SharePoint Core Functions
	. .\SP_Core.ps1
	forEach ($function in $FunctionsToRun) {
		. .\Functions\$function.ps1
		[array]$Csv = @(Import-Csv $CSVFolderPath\$function.csv)
		&(Get-Item "function:$function").ScriptBlock -Rows $Csv
	}

	Write-Host "## DONE ##" -ForegroundColor Green