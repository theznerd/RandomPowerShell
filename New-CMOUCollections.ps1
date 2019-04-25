## Given a CSV with a list of OUs in a column named OU
## this script will create collections for devices contained
## in those OUs.
$csv = Import-Csv "path\to\csv"
foreach($c in $csv)
{
    $name = $c.OU.Replace(",DC=___,DC=___","").Replace("CN=","").Replace("OU=","").Split(",") #replace the DCs
    $colName = "" #anything you wish to prepend to the Collection name
    for($i = 1; $i -le $name.Count; $i++)
    {
        if($i -ne ($name.Count))
        {
            $colName += "$($name[-$i]) - "
        }
        else
        {
            $colName += "$($name[-$i])"
        }
    }
    Write-Host -ForegroundColor Green "Working: $($c.OU)"
    Write-Host "    Creating Collection: $colName"
    $null = New-CMDeviceCollection -Name "$colName" -Comment "" -LimitingCollectionName "" #don't forget to set comment/limiting collection
    Write-Host "    Query:  `"select * from SMS_R_System where SMS_R_System.DistinguishedName like `"%$($c.OU)`"`""
    $null = Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$colName" -RuleName "OU Query" -QueryExpression "select * from SMS_R_System where SMS_R_System.DistinguishedName like `"%$($c.OU)`""
}
