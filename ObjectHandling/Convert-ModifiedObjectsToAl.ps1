﻿<# 
 .Synopsis
  Convert modified objects in a Nav container to AL
 .Description
  This command will invoke the 4 commands in order to export modified objects and convert them to AL:
  1. Export-NavContainerObjects
  2. Create-MyOriginalFolder
  3. Create-MyDeltaFolder
  4. Convert-Txt2Al
  A folder with the name of the container is created underneath c:\programdata\navcontainerhelper\extensions for holding all the temp and the final output.
  The command will open a windows explorer window with the output
 .Parameter containerName
  Name of the container for which you want to export and convert objects
 .Parameter sqlCredential
  Credentials for the SQL admin user if using NavUserPassword authentication. User will be prompted if not provided
 .Parameter startId
  Starting offset for objects created by the tool (table and page extensions)
 .Parameter filter
  Filter specifying the objects you want to convert (default is modified=1)
 .Parameter openFolder
  Switch telling the function to open the result folder in Windows Explorer when done
 .Example
  Convert-ModifiedObjectsToAl -containerName test
 .Example
  Convert-ModifiedObjectsToAl -containerName test -sqlCredential (get-credential -credential 'sa') -startId 881200
#>
function Convert-ModifiedObjectsToAl {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $containerName, 
        [System.Management.Automation.PSCredential]$sqlCredential = $null,
        [int]    $startId = 50100,
        [string] $filter = "None",
        [switch] $openFolder,
        [switch] $doNotUseDeltas
    )

    $sqlCredential = Get-DefaultSqlCredential -containerName $containerName -sqlCredential $sqlCredential -doNotAskForCredential
    $txt2al = Invoke-ScriptInNavContainer -containerName $containerName -ScriptBlock { $txt2al }
    if (!($txt2al)) {
        throw "You cannot run Convert-ModifiedObjectsToAl on this Nav Container, the txt2al tool is not present."
    }

    $suffix = "-newsyntax"

    if ($doNotUseDeltas) {
        if ($filter -ne "None") {
            throw "You cannot set the filter if you are using doNotUseDeltas - you need to convert the full app"
        }
        $myDeltaFolder  = Join-Path $ExtensionsFolder "$containerName\objects$suffix"
        Export-NavContainerObjects -containerName $containerName -sqlCredential $sqlCredential -objectsFolder $myDeltaFolder -exportTo 'txt folder (new syntax)' -filter ""
    }
    else {
        if ($filter -eq "None") {
            $filter = "Modified=1"
        }
        Export-ModifiedObjectsAsDeltas -containerName $containerName -sqlCredential $sqlCredential -useNewSyntax -filter $filter
    }

    $myAlFolder       = Join-Path $ExtensionsFolder "$containerName\al$suffix"

    Convert-Txt2Al -containerName $containerName `
                   -myDeltaFolder $myDeltaFolder `
                   -myAlFolder $myAlFolder `
                   -startId $startId

    if ($openFolder) {
        Start-Process $myAlFolder
        Write-Host "al files created in $myAlFolder"
    }
    $myAlFolder
}
Export-ModuleMember -Function Convert-ModifiedObjectsToAl
