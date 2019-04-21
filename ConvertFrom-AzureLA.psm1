<#
    .Synopsis
    Converts the JSON array returned from a Azure Log Analytics API to an array of objects.
#>
function ConvertFrom-AzureLA
{
    [cmdletbinding()]
    param
    (
        [parameter(ValueFromPipeline)]
        $LogAnalyticsData
    )
    Begin
    {
        $output = @()
    }
    Process
    {
        $columns = $LogAnalyticsData.tables.columns
        $rows = $LogAnalyticsData.tables.rows
        foreach($row in $rows)
        {
            $psco = [PSCustomObject]@{}
            for($c = 0; $c -lt $columns.count; $c++)
            {
                Add-Member -InputObject $psco -MemberType NoteProperty -Name $columns[$c].name -Value $row[$c]
            }
            $output += $psco
        }
    }
    End
    {
        return $output
    }
}
Export-ModuleMember -Function ConvertFrom-AzureLA
