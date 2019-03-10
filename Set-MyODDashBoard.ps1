<# 
.SYNOPSIS 
Read json file with OctopusDeploy Dashboard settings either from restapi url param or from file.
.DESCRIPTION 
You need your own octopus deploy api-key. See https://octopus.com/docs/api-and-integration/api/how-to-create-an-api-key. -dashboard param can be either name of dashboard, file or url.
When using rest api a tempfile is created and then read from. this tempfile is not deleted if error or param switch -keeptemp is given.
.EXAMPLE 
 List avaible dashboards from  default apiserver http://version.skandianordic.org/api/octopusDashboard --  .\Set-MyODDashboard.ps1 
.EXAMPLE 
 Simle get a release from default apiserver http://version.skandianordic.org/api/octopusDashboard --  .\Set-MyODDashboard.ps1 REL2100
 .EXAMPLE 
Save currentDashboard as local file   .\Set-MyODDashboard.ps1 -SaveCurrentAsFile "c:\myboards\MybestBoard.json"
.EXAMPLE 
Pipe your own dashboard from file instead "C:\myoddashboards\OnlyDataVXLInProd.js\"| .\Set-MyODDashboard.ps1
.EXAMPLE 
Keep tempfile:  .\Set-MyODDashboard.ps1 -dashboard REL2101 -keeptempfile  
.PARAMETER dashboard
path either as eg REL2100 will choose rel2100.json file on default restservice else if \ is part of name it will look for local json file.
.PARAMETER keeptempfile 
Keeps the tempfile that was downloaded from external rest.If you want to debug or make it a localfile. 
.PARAMETER SaveCurrentAsFile 
Saves current dashboard as local jsonfile.
.LINK 
latest version 
http://github.com/patriklindstrom/Powershell-pasen 
.LINK 
About Author and script 
http://www.lcube.se 
.LINK 
 https://octopus.com/docs/api-and-integration/api/how-to-create-an-api-key
 .LINK 
 https://octopus.com/docs/api-and-integration/octopus-rest-api
.NOTES 
    File Name  : Set-MyOdDashboard.ps1 
    Author     : Patrik Lindström LCube 
    Requires   : PowerShell V5  
#> 
param  
(  
    [Parameter( 
        Position=0, 
        Mandatory=$false, 
        ValueFromPipeline=$true, 
        ValueFromPipelineByPropertyName=$true) 
    ] 
    [Alias('config')] 
    [Alias('d')]  
    [string]$DashBoard , 
    [Parameter( 
        Position=1, 
        Mandatory=$false, 
        ValueFromPipeline=$false, 
        ValueFromPipelineByPropertyName=$true) 
    ] 
    [Alias('temp')] 
    [Alias('t')]
    [switch]$KeepTempFile
    , 
    [Parameter( 
        Position=2, 
        Mandatory=$false, 
        ValueFromPipeline=$false, 
        ValueFromPipelineByPropertyName=$true) 
    ] 
    [Alias('api')] 
    [Alias('a')]
    [string]$apiKey =  'API-W9M1'  
        , 
    [Parameter( 
        Position=3, 
        Mandatory=$false, 
        ValueFromPipeline=$false, 
        ValueFromPipelineByPropertyName=$true) 
    ] 
    [Alias('save')] 
    [Alias('s')]
    [string]$SaveCurrentAsFile 
        
)
$octopusDeployDashboardFilterConfigFile = $null
$octopusDeployDashboardFilterConfigURL = "http://localhost/api/dashboardconfiguration/" 
$DeployDashboardFilterConfigURL = "http://localhost/api/octopusDashboard/"
$apiHeader = @{"X-Octopus-ApiKey" = $apiKey} 
$GetDataMode = "None"
$tempJsonFile = [System.IO.Path]::GetTempFileName()
if($SaveCurrentAsFile){
try
{
    $octopusDashBoardInformation = Invoke-RestMethod -Method get -Uri $octopusDeployDashboardFilterConfigURL -Headers $apiHeader -OutFile $SaveCurrentAsFile
    Write-Host "saved current Dashboard as json file here: $SaveCurrentAsFile"
}
catch{
   Write-Host "Unable to get current ctopus Deploy Dashboard and save it " -ForegroundColor Red
   Write-Host $_.Exception.Message -ForegroundColor Red
    return -1
}
}
# Decide how to parse Dashboard data is i part of url, url  or file? If cant pars then list all items on default api server and exit script
# if dashboard param is empty then list dashboard configs.
if (!($DashBoard)) {
$GetDataMode = "List"
$cred = Get-Credential
    $dashb = $(Invoke-WebRequest -Uri $DeployDashboardFilterConfigURL -UseDefaultCredentials).AllElements | where outerhtml -Like '<A href="/api/octopusDashboard/*' | where innertext -Like "*.json"  | Select  -ExpandProperty innerText | sort -Descending | %{if ($_ -cmatch '(.*)\.json') {$matches[1]} else {''}}
 $dashb
   write-host "These dashboard are avaible on default $DeployDashboardFilterConfigURL " -ForegroundColor DarkGreen -BackgroundColor White
   write-host "to get help for script " -nonewline -ForegroundColor DarkGreen  -BackgroundColor White ;write-host  "Get-Help .\Set-MyODDashBoard.ps1 -example" -ForegroundColor Darkred  -BackgroundColor White
   write-host "Take a chance choose one for example: " -nonewline -ForegroundColor DarkGreen  -BackgroundColor White ;write-host  "Set-MyODDashboard -dashboard $($dashb | select -first 1)" -ForegroundColor Darkred  -BackgroundColor White
 # Exit the whole script   
   exit ; 
}
# try to parse and guess if use restapi or read file.
switch -regex ($DashBoard)  { 
 
 ('.*\\[^\\]*\.json' ) {$GetDataMode = "File"; Write-Host "get from file was choosen"
                        $octopusDeployDashboardFilterConfigFile = $DashBoard
                        ;break}
 ('\A\w*\Z' )  {$GetDataMode = "Rest";

$tempJsonFile = [System.IO.Path]::GetTempFileName()
try
{
Write-debug "Saving to jsonfile tempfile: $($tempJsonFile.ToString())"
if ($KeepTempFile)
{Write-host "Saving to jsonfile tempfile: $($tempJsonFile.ToString())"}
$restapipath = "$DeployDashboardFilterConfigURL/$DashBoard.json"
Write-debug $restapipath
$octopusDashBoardInformationSavedData =  Invoke-RestMethod -Method get -Uri $restapipath -OutFile $tempJsonFile.ToString()
$octopusDeployDashboardFilterConfigFile = $tempJsonFile.ToString()
}
catch
{
    Write-Host "Unable to find Octopus Deploy Dashboard config mode $GetDataMode " -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    return -1
}                 
                 ;break}
   default  {
    Throw "Cant understand parameter Dashboard - do not know what to do"

   } # end default
}
write-verbose "Start getting octopusDashboardInformation from file  $octopusDeployDashboardFilterConfigFile  at $(((get-date)).ToString("yyyyMMddThhmmss"))" 
write-debug "octopusServerDeploymentsURL $octopusDeployDashboardDataURL"
$octopusDashBoardInformationObj = (Get-Content -Raw -Path $octopusDeployDashboardFilterConfigFile)|ConvertFrom-Json
# should we remove the tempfile. If it exist remove it.
if ($KeepTempFile){
    Write-Host "Tempfile can be found here: $($tempJsonFile.ToString()) "
} else {
if ($tempJsonFile){
    if(Test-Path $tempJsonFile.ToString()){    Remove-Item $tempJsonFile.ToString()}}
}
write-verbose "Start put octopusDashBoardFilter from file $($octopusDeployDashboardFilterConfigFile) via restapi on server $octopusDeployDashboardFilterConfigURL $(((get-date)).ToString("yyyyMMddThhmmss"))" 
try
{
    $result = Invoke-RestMethod -Method put -Uri $octopusDeployDashboardFilterConfigURL  -Headers $apiHeader -body ($octopusDashBoardInformationObj |  ConvertTo-Json) 
}
catch
{
    Write-Host "Unable to put Octopus Deploy Dashboard config" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    return -1
}
Write-host "Done getting ODDashBoardInfo at $(((get-date)).ToString("yyyyMMddThhmmss"))"  -ForegroundColor Green
$octopusDashBoardInformationObj