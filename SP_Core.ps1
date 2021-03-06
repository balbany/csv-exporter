<#
	SharePoint Functions, called from DeploySP.ps1

Function Example ($Rows) {
    Write-Host "Deploying Example..." -ForegroundColor White
	ForEach( $row in $Rows ) {
        $splatRow = getSplat -Input $row
        Write-Host "    -   Ensuring example" $splatRow.Identity -ForegroundColor White
        #Call lower level cmdlet/function for the current row here

    }
}

#>

Function getSplat($InputRow) {
    $InputRow.psobject.Properties | Where-Object {$_.Value} | ForEach-Object -Begin {
	    $SplatParams = @{}
    } -Process {
        if($_.Value -eq 'TRUE') {
            $SplatParams[$_.Name] = $true
        } elseif($_.Value -eq 'FALSE') {
	        $SplatParams[$_.Name] = $false
        } else {
            $SplatParams[$_.Name] = $_.Value
        }
    }
    return $SplatParams
}

Function Invoke-Splat {
    <#
    .Synopsis
        Splats a hashtable on a function in a safer way than the built-in
        mechanism.
    .Example
        Invoke-Splat Get-XYZ $PSBoundParameters
    #>
    param(
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=0)]
        [string]
        $FunctionName,
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, Position=1)]
        [System.Collections.Hashtable]
        $Parameters
    )
 
    $h = @{}
    ForEach ($key in (gcm $FunctionName).Parameters.Keys) {
        if ($Parameters.$key) {
            $h.$key = $Parameters.$key
        }
    }
    if ($h.Count -eq 0) {
        $FunctionName | Invoke-Expression
    }
    else {
        "$FunctionName @h" | Invoke-Expression
    }
}