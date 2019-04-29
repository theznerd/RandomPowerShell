$resources = Get-ChildItem -Path "$PSScriptRoot\Resources\*.dll" -ErrorAction SilentlyContinue
$XAML = Get-ChildItem -Path "$PSScriptRoot\XAML\*.xaml" -ErrorAction SilentlyContinue
$StaticResources = Get-ChildItem -Path "$PSScriptRoot\StaticResources" -ErrorAction SilentlyContinue

###################
## Import Resources
###################
# Load WPF
Add-Type -assemblyName PresentationFramework

# Load Resources
foreach($dll in $resources) { [System.Reflection.Assembly]::LoadFrom("$($dll.FullName)") | out-null }

##############
## Import XAML
##############
$xp = '[^a-zA-Z_]'
$vx = @()
foreach($x in $XAML) { 
    $xaml = Get-Content $x.FullName
    $xaml = $xaml -replace "x:N",'N' -replace 'mc:Ignorable="d"','' -replace "x:Class=`"(.*?)`"",''
    New-Variable -Name "xaml$(($x.BaseName) -replace $xp, '')" -Value ($xaml -as [xml]) -Force 
    $vx += "$(($x.BaseName) -replace $xp, '')"
}

#######################
## Add Static Resources
#######################
$imageFileTypes = @(".jpg",".bmp",".gif",".tif",".png")
if($StaticResources.Count -gt 0){
    foreach($v in $vx)
    {
        $xml = ((Get-Variable -Name "xaml$($v)").Value)
        if(!($xml.DocumentElement.'Window.Resources'))
        {
            $rd = $xml.CreateElement('ResourceDictionary')
            $wr = $xml.CreateElement('Window.Resources')
            $wr.AppendChild($rd)
            $xml.DocumentElement.AppendChild($wr)
        }
        foreach($sr in $StaticResources)
        {
            if($sr.Extension -in $imageFileTypes)
            {
                $xml.DocumentElement.'Window.Resources'.ResourceDictionary.InnerXml += "<Image x:Key=`"$($sr.BaseName)`" Source=`"$($sr.FullName)`" />"
                ## THIS APPEARS TO BE BROKEN... :/
                #$newSR = $xml.CreateElement('Image')
                #$newSR.SetAttribute("Key","x","$($sr.BaseName)")
                #$newSR.SetAttribute('Source',"$($sr.FullName)")
                #$xml.DocumentElement.'Window.Resources'.ResourceDictionary.AppendChild($newSR)
            }    
        }
        (Get-Variable -Name "xaml$($v)").Value = $xml
    }
}

#################
## Create "Forms"
#################
$forms = @()
foreach($x in $vx)
{
    $Reader = (New-Object System.Xml.XmlNodeReader ((Get-Variable -Name "xaml$($x)").Value)) 
    New-Variable -Name "form$($x)" -Value ([Windows.Markup.XamlReader]::Load($Reader)) -Force
    $forms += "form$($x)"
}

#################################
## Create Controls (Buttons, etc)
#################################
$controls = @()
foreach($x in $vx)
{
    $xaml = (Get-Variable -Name "xaml$($x)").Value
    $xaml.SelectNodes("//*[@Name]") | %{
        Set-Variable -Name "form$($x)Control$($_.Name)" -Value (Get-Variable -Name "form$($x)").Value.FindName($_.Name)
        $controls += (Get-Variable -Name "form$($x)Control$($_.Name)").Name
    }
}

############################
## FORMS AND CONTROLS OUTPUT
############################
Write-Host -ForegroundColor Cyan "The following forms were created:"
$forms | %{ Write-Host -ForegroundColor Yellow "  `$$_"}
if($controls.Count -gt 0){
    Write-Host ""
    Write-Host -ForegroundColor Cyan "The following controls were created:"
    $controls | %{ Write-Host -ForegroundColor Yellow "  `$$_"}
}

########################
## WIRE UP YOUR CONTROLS
########################
# example: $formMainWindowControlButton.Add_Click({ your code })

#############################
###### BEGIN YOUR WORK ######
#############################
[void]$formMainWindow.ShowDialog()
