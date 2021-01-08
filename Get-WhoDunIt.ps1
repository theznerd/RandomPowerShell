### Set the following parameters
$cmServer = "localhost"
$cmSite = "P01"
$pathToDLLs = "P:\Program Files\Microsoft Configuration Manager\bin\X64\system32\smsmsgs\"
 
#region Definitions
Class SearchFilter {
    [string]$WMIProperty
    [string]$FriendlyName
    [string]$Value
    [bool]$Wildcard = $false
}

Class SearchDefinition {
    [string]$FriendlyName
    [int]$MessageID
    SearchDefinition([int]$m, [string]$f)
    {
        $this.MessageID = $m
        $this.FriendlyName = $f
    }
}

Class SearchCollection {
    [string]$FriendlyName
    [SearchDefinition[]]$SearchDefinitions
    [SearchFilter[]]$SearchFilters
    [datetime]$StartTime = [datetime]::MinValue
    [datetime]$EndTime = [datetime]::MaxValue
    SearchCollection()
    {
        $this.SearchDefinitions = @()
        $this.SearchFilters = @()
    }
}

$SearchCollections = @()

#region Collections
$sdCollectionCreate = [SearchDefinition]::new(30015, "Collection Created")
$sdCollectionModify = [SearchDefinition]::new(30016, "Collection Modified")
$sdCollectionDelete = [SearchDefinition]::new(30017, "Collection Removed")
$sfCollectionID = [SearchFilter]::new()
$sfCollectionID.FriendlyName = "Collection ID"
$sfCollectionID.WMIProperty = "InsString2"
$sfCollectionUser = [SearchFilter]::new()
$sfCollectionUser.FriendlyName = "Username"
$sfCollectionUser.WMIProperty = "InsString1"
$sfCollectionUser.Wildcard = $true
$scCollections = [SearchCollection]::new()
$scCollections.FriendlyName = "Collections Add/Remove/Delete"
$scCollections.SearchDefinitions += $sdCollectionCreate
$scCollections.SearchDefinitions += $sdCollectionModify
$scCollections.SearchDefinitions += $sdCollectionDelete
$scCollections.SearchFilters += $sfCollectionID
$scCollections.SearchFilters += $sfCollectionUser
$SearchCollections += $scCollections
#endregion Collections
#endregion Definitions

#region PInvoke
$sigFormatMessage = @'
[DllImport("kernel32.dll")]
public static extern uint FormatMessage(uint flags, IntPtr source, uint messageId, uint langId, StringBuilder buffer, uint size, string[] arguments);
'@ 
$sigGetModuleHandle = @'
[DllImport("kernel32.dll")]
public static extern IntPtr GetModuleHandle(string lpModuleName);
'@ 
$sigLoadLibrary = @'
[DllImport("kernel32.dll")]
public static extern IntPtr LoadLibrary(string lpFileName);
'@ 
$Win32FormatMessage = Add-Type -MemberDefinition $sigFormatMessage -name "Win32FormatMessage" -namespace Win32Functions -PassThru -Using System.Text
$Win32GetModuleHandle = Add-Type -MemberDefinition $sigGetModuleHandle -name "Win32GetModuleHandle" -namespace Win32Functions -PassThru -Using System.Text
$Win32LoadLibrary = Add-Type -MemberDefinition $sigLoadLibrary -name "Win32LoadLibrary" -namespace Win32Functions -PassThru -Using System.Text
#endregion PInvoke

# Load Appropriate DLLs
$srvmsgsDLL = $Win32LoadLibrary::LoadLibrary("$pathToDLLs\SRVMSGS.DLL")
$srvmsgsHandle = $Win32GetModuleHandle::GetModuleHandle("$pathToDLLs\SRVMSGS.DLL")
$provmsgsDLL = $Win32LoadLibrary::LoadLibrary("$pathToDLLs\PROVMSGS.DLL")
$provmsgsHandle = $Win32GetModuleHandle::GetModuleHandle("$pathToDLLs\PROVMSGS.DLL")
$climsgsDLL = $Win32LoadLibrary::LoadLibrary("$pathToDLLs\CLIMSGS.DLL")
$climsgsHandle = $Win32GetModuleHandle::GetModuleHandle("$pathToDLLs\CLIMSGS.DLL")
$dllHash = @{
    "SMS Provider" = $provmsgsHandle
}


Write-Host "**************************"
Write-Host "****** CM WhoDunIt! ******"
Write-Host "**************************"
$selectionIndex = -1
for($i = 1; $i -le $SearchCollections.Count; $i++)
{
    Write-Host -ForegroundColor Gray "$i`: $($SearchCollections[$i - 1].FriendlyName)"
}
do{
    $selection = Read-Host -Prompt "Please select a search"
}while(![int]::TryParse($selection, [ref]$selectionIndex) -or !($selection -ge 1) -or !($selection -le $SearchCollections.Count))
$selectionIndex-- # Zero Index

Write-Host ""
Write-Host "****** Input filters ******"
foreach($filter in $SearchCollections[$selectionIndex].SearchFilters)
{
    $rhText = "$($filter.FriendlyName)"
    if($filter.Wildcard){$rhText += " (use % for wildcard)"}
    $filter.Value = Read-Host "$rhText"
}
$startTime = Read-Host "Events since (ex 1/10/2020 11:30:00 AM)"
$startTimeOut = [datetime]::MaxValue
if([datetime]::TryParse($startTime, [ref]$startTimeOut))
{
    $SearchCollections[$selectionIndex].StartTime = $startTimeOut
}
$endTime = Read-Host "Events before (ex 1/10/2021 11:30:00 AM)"
$endTimeOut = [datetime]::MaxValue
if([datetime]::TryParse($endTime, [ref]$endTimeOut))
{
    $SearchCollections[$selectionIndex].EndTime = $endTimeOut
}
 
Write-Host ""
Write-Host "****** Starting Search ******"
$results = @()

#Build Search Filter
$searchFilter = ""
for($i = 0; $i -le $SearchCollections[$selectionIndex].SearchFilters.Count; $i++)
{
    if(![string]::IsNullOrWhiteSpace($SearchCollections[$selectionIndex].SearchFilters[$i].Value))
    {
        if($i -ne 0)
        {
            $searchFilter += " and "
        }
        if($SearchCollections[$selectionIndex].SearchFilters[$i].Wildcard)
        {
            $searchFilter += $SearchCollections[$selectionIndex].SearchFilters[$i].WMIProperty + " like " + "'" + $SearchCollections[$selectionIndex].SearchFilters[$i].Value + "'"
        }
        else
        {
            $searchFilter += $SearchCollections[$selectionIndex].SearchFilters[$i].WMIProperty + "=" + "'" + $SearchCollections[$selectionIndex].SearchFilters[$i].Value + "'"
        }
    }
}
 
# Add Date Filters
if($SearchCollections[$selectionIndex].StartTime -ne [datetime]::MinValue)
{
    if(![string]::IsNullOrWhiteSpace($searchFilter)){$searchFilter += " and "}
    $searchFilter += "Time > '" + $SearchCollections[$selectionIndex].StartTime.ToString("yyyy-MM-dd HH:mm:ss:mmm") + "'"
}
if($SearchCollections[$selectionIndex].EndTime -ne [datetime]::MaxValue)
{
    if(![string]::IsNullOrWhiteSpace($searchFilter)){$searchFilter += " and "}
    $searchFilter += "Time < '" + $SearchCollections[$selectionIndex].EndTime.ToString("yyyy-MM-dd HH:mm:ss:mmm") + "'"
}
 
#Search
foreach($searchDefinition in $SearchCollections[$selectionIndex].SearchDefinitions)
{
    $thisSearch = $searchFilter
    if([string]::IsNullOrWhiteSpace($thisSearch))
    {
        $thisSearch = "MessageID='$($searchDefinition.MessageID)'"
    }
    else
    {
        $thisSearch += " and MessageID='$($searchDefinition.MessageID)'"
    }
    $results += Get-CimInstance -ComputerName $cmServer -Namespace "root\sms\site_$cmSite" -ClassName "SMS_StatMsgWithInsStrings" -Filter $thisSearch
}

# Format Results
$fResults = @()
foreach($r in $results)
{
    $sizeOfBuffer = [int]16384
    $stringArrayInput = {"%1","%2","%3","%4","%5", "%6", "%7", "%8", "%9"}
    $flags = 0x00000800 -bor 0x00000200
    $stringOutput = New-Object System.Text.StringBuilder $sizeOfBuffer 

    # Set pointer to correct module
    $ptrModule = $dllHash[$r.ModuleName]

    $result = $Win32FormatMessage::FormatMessage($flags, $ptrModule, $r.Severity -bor $r.MessageID, 0, $stringOutput, $sizeOfBuffer, $stringArrayInput)

    $stringOutput = $stringOutput.ToString().
                                  Replace("%11","").
                                  Replace("%12","").
                                  Replace("%3%4%5%6%7%8%9%10","").
                                  Replace("%1",$r.InsString1).
                                  Replace("%2",$r.InsString2).
                                  Replace("%3",$r.InsString3).
                                  Replace("%4",$r.InsString4).
                                  Replace("%5",$r.InsString5).
                                  Replace("%6",$r.InsString6).
                                  Replace("%7",$r.InsString7).
                                  Replace("%8",$r.InsString8).
                                  Replace("%9",$r.InsString9).
                                  Replace("%10",$r.InsString10)
    $fr = [PSCustomObject]@{
        Type = ($SearchCollections[$selectionIndex].SearchDefinitions | Where-Object {$_.MessageID -eq $r.MessageID}).FriendlyName
        Date = $r.Time
        Message = $stringOutput
    }
    $fResults += $fr
}
 
# Return results
return $fResults
