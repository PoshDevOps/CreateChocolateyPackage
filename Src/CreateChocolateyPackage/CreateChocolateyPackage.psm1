# halt immediately on any errors which occur in this module
$ErrorActionPreference = "Stop"

function Invoke(

[String]
[ValidateNotNullOrEmpty()]
[Parameter(
    Mandatory=$true,
    ValueFromPipelineByPropertyName=$true)]
$PoshDevOpsProjectRootDirPath,

[String[]]
[ValidateCount(1,[Int]::MaxValue)]
[Parameter(
    ValueFromPipelineByPropertyName = $true)]
$IncludeNuspecPath = @(gci -Path $PoshDevOpsProjectRootDirPath -File -Filter '*.nuspec' -Recurse | %{$_.FullName}),

[String[]]
[Parameter(
    ValueFromPipelineByPropertyName = $true)]
$ExcludeNuspecNameLike,

[Switch]
[Parameter(
    ValueFromPipelineByPropertyName=$true)]
$Recurse,

[String]
[Parameter(
    ValueFromPipelineByPropertyName = $true)]
$Version,

[String]
[ValidateNotNullOrEmpty()]
[Parameter(
    ValueFromPipelineByPropertyName=$true)]
$PathToChocolateyExe = 'C:\ProgramData\chocolatey\bin\chocolatey.exe'){

    $NuspecFilePaths = gci -Path $IncludeNuspecPath -Filter '*.nuspec' -File -Exclude $ExcludeNuspecNameLike -Recurse:$Recurse | ?{!$_.PSIsContainer} | %{$_.FullName}

Write-Debug `
@"
`Located .nuspec's:
$($NuspecFilePaths | Out-String)
"@

    $initialLocation = Get-Location

    Try{
        foreach($nuspecFilePath in $NuspecFilePaths)
        {
            Set-Location (Split-Path $nuspecFilePath -Parent)

            $chocolateyParameters = @('pack',$nuspecFilePath)
        
            if($Version){
                $chocolateyParameters += @('--version',$Version)
            }

Write-Debug `
@"
Invoking choco:
& $PathToChocolateyExe $($chocolateyParameters|Out-String)
"@
            & $PathToChocolateyExe $chocolateyParameters

            # handle errors
            if ($LastExitCode -ne 0) {
                throw $Error
            }
        }
    }
    Finally{
        Set-Location $initialLocation
    }
}

Export-ModuleMember -Function Invoke