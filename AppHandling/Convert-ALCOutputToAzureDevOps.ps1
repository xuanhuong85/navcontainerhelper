<#
 .Synopsis
  Convert Output from AL Compiler and output to host in Azure DevOps format
 .Description
  This function is a contribution from Microsoft MVP Kamil Sacek, read about it here:
  https://dynamicsuser.net/nav/b/kine/posts/alc-exe-output-formatting-for-tfs-vsts
 .Parameter AlcOutput
  One or more lines of outout from the AL Compiler
 .Example
  Compile-AppInNavContainer -containerName test -credential $credential -appProjectFolder "C:\Users\freddyk\Documents\AL\Test" -AzureDevOps
 .Example
  & .\alc.exe /project:$appProjectFolder /packagecachepath:$appSymbolsFolder /out:$appOutputFile | Convert-AlcOutputToAzureDevOps
#>
Function Convert-AlcOutputToAzureDevOps {
    Param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        $AlcOutput
    )

    Process {
        foreach($line in $AlcOutput) {
            switch -regex ($line) {
                "^warning (\w{2}\d{4}):(.*('.*').*|.*)$" {
                    if (Test-Path $Matches[3]) {
                        Write-Host "##vso[task.logissue type=warning;sourcepath=$($Matches[3]);code=$($Matches[1]);]$($Matches[2])"
                    } else {
                        Write-Host "##vso[task.logissue type=warning;code=$($Matches[1]);]$($Matches[2])"
                    }
            
                }
                "^(.*)\((\d+),(\d+)\): error (\w{2}\d{4}): (.*)$"
                #Objects\codeunit\Cod50130.name.al(62,30): error AL0118: The name '"Parent Object"' does not exist in the current context        
                {
                    Write-Host "##vso[task.logissue type=error;sourcepath=$($Matches[1]);linenumber=$($Matches[2]);columnnumber=$($Matches[3]);code=$($Matches[4]);]$($Matches[5])"
                }
                "^(.*)\((\d+),(\d+)\): warning (\w{2}\d{4}): (.*)$"
                #Prepared for unified warning format
                #Objects\codeunit\Cod50130.name.al(62,30): warning AL0118: The name '"Parent Object"' does not exist in the current context        
                {
                    Write-Host "##vso[task.logissue type=warning;sourcepath=$($Matches[1]);linenumber=$($Matches[2]);columnnumber=$($Matches[3]);code=$($Matches[4]);]$($Matches[5])"
                }
                default {
                    Write-Host $line
                }
            }
        }
    }
}

Export-ModuleMember Convert-AlcOutputToAzureDevOps