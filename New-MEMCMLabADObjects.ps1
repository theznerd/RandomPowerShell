#Requires -Modules ActiveDirectory
#Requires -Version 5
## Yes, they're all Top Gun characters

Import-Module ActiveDirectory
$rootDN = Read-Host -Prompt "Root DN in Distinguished Name (e.g. DC=znerd,DC=dev)"
$domain = Read-Host -Prompt "Domain for User Principal Name (e.g. znerd.dev)"
$password = Read-Host -Prompt "Password for all accounts (yes, all of them, it's a lab)" -AsSecureString

# User Definitions
class SADUser {
    [string]$GivenName
    [string]$Surname
    [string]$AccountType
    [string]$Callsign
    SADUser(
        [string]$GivenName,
        [string]$Callsign,
        [string]$Surname,
        [string]$AccountType)
    {
        $this.GivenName = $GivenName
        $this.Surname = $Surname
        $this.Callsign = $Callsign
        $this.AccountType = $AccountType
    }
}

$users = @(
    [SADUser]::new("Mike","Viper","Metcalf","Standard")
    [SADUser]::new("Rick","Jester","Heatherly","Standard")
    [SADUser]::new("Pete","Maverick","Mitchell","Standard")
    [SADUser]::new("Tom","Iceman","Kazansky","Standard")
    [SADUser]::new("Sam","Merlin","Wells","Standard")
    [SADUser]::new("Nick","Goose","Bradshaw","Standard")
    [SADUser]::new("Charlotte","Charlie","Blackwood","Standard")
    [SADUser]::new("Mike","Viper","Metcalf","EnterpriseAdmin")
    [SADUser]::new("Rick","Jester","Heatherly","DomainAdmin")
    [SADUser]::new("Pete","Maverick","Mitchell","ServerAdmin")
    [SADUser]::new("Tom","Iceman","Kazansky","ServerAdmin")
    [SADUser]::new("Sam","Merlin","Wells","WorkstationAdmin")
    [SADUser]::new("Nick","Goose","Bradshaw","WorkstationAdmin")
    [SADUser]::new("F-14A","sql","Tomcat","Service")
    [SADUser]::new("Mikoyan","orchestrator","MiG-28","Service")
)

# Create OUs
New-ADOrganizationalUnit -Name "_Users" -Path "$rootDN"
New-ADOrganizationalUnit -Name "Administrative" -Path "OU=_Users,$rootDN"
New-ADOrganizationalUnit -Name "Standard" -Path "OU=_Users,$rootDN"
New-ADOrganizationalUnit -Name "Service" -Path "OU=_Users,$rootDN"

New-ADOrganizationalUnit -Name "_Servers" -Path "$rootDN"
New-ADOrganizationalUnit -Name "MEMCM" -Path "OU=_Servers,$rootDN"

New-ADOrganizationalUnit -Name "_Workstations" -Path "$rootDN"

New-ADOrganizationalUnit -Name "_Groups" -Path "$rootDN"

# Create Groups
$saGroup = New-ADGroup -Name "Server Admins" -Path "OU=_Groups,$rootDN" -GroupScope Global -GroupCategory Security -PassThru
$waGroup = New-ADGroup -Name "Workstation Admins" -Path "OU=_Groups,$rootDN" -GroupScope Global -GroupCategory Security -PassThru
$cmGroup = New-ADGroup -Name "MEMCM Full Admins" -Path "OU=_Groups,$rootDN" -GroupScope Global -GroupCategory Security -PassThru
$eaGroup = Get-ADGroup "CN=Enterprise Admins,CN=Users,$rootDN"
$daGroup = Get-ADGroup "CN=Domain Admins,CN=Users,$rootDN"

# Create Users
foreach($user in $users)
{
    $userDefinition = @{
        GivenName = "$($user.GivenName)"
        Surname = "$($user.Surname)"
        AccountPassword = $password
        PasswordNeverExpires = $true
        ChangePasswordAtLogon = $false
        Enabled = $true
    }
    if($user.AccountType -eq "Standard")
    {
        $userDefinition.Add("DisplayName","$($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("Name","$($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("SamAccountName","$($user.Callsign)")
        $userDefinition.Add("UserPrincipalName","$($user.Callsign)@$domain")
        $userDefinition.Add("Path","OU=Standard,OU=_Users,$rootDN")
    }
    elseif($user.AccountType -eq "EnterpriseAdmin")
    {
        $userDefinition.Add("DisplayName","(EA) $($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("Name","(EA) $($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("SamAccountName","ea.$($user.Callsign)")   
        $userDefinition.Add("UserPrincipalName","ea.$($user.Callsign)@$domain")
        $userDefinition.Add("Path","OU=Administrative,OU=_Users,$rootDN") 
    }
    elseif($user.AccountType -eq "DomainAdmin")
    {
        $userDefinition.Add("DisplayName","(DA) $($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("Name","(DA) $($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("SamAccountName","da.$($user.Callsign)") 
        $userDefinition.Add("UserPrincipalName","da.$($user.Callsign)@$domain")
        $userDefinition.Add("Path","OU=Administrative,OU=_Users,$rootDN")   
    }
    elseif($user.AccountType -eq "ServerAdmin")
    {
        $userDefinition.Add("DisplayName","(SA) $($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("Name","(SA) $($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("SamAccountName","sa.$($user.Callsign)")  
        $userDefinition.Add("UserPrincipalName","sa.$($user.Callsign)@$domain")
        $userDefinition.Add("Path","OU=Administrative,OU=_Users,$rootDN")  
    }
    elseif($user.AccountType -eq "WorkstationAdmin")
    {
        $userDefinition.Add("DisplayName","(WA) $($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("Name","(WA) $($user.GivenName) '$($user.Callsign)' $($user.Surname)")
        $userDefinition.Add("SamAccountName","wa.$($user.Callsign)")  
        $userDefinition.Add("UserPrincipalName","wa.$($user.Callsign)@$domain")
        $userDefinition.Add("Path","OU=Administrative,OU=_Users,$rootDN")  
    }
    elseif($user.AccountType -eq "Service")
    {
        $userDefinition.Add("DisplayName","(Service) $($user.GivenName) $($user.Surname)")
        $userDefinition.Add("Name","(Service) $($user.GivenName) $($user.Surname)")
        $userDefinition.Add("SamAccountName","service.$($user.Callsign)")  
        $userDefinition.Add("UserPrincipalName","service.$($user.Callsign)@$domain")
        $userDefinition.Add("Path","OU=Service,OU=_Users,$rootDN")  
    }
    New-ADUser @userDefinition

    if($user.AccountType -eq "EnterpriseAdmin")
    {
        Add-ADGroupMember $eaGroup -Members $userDefinition["SamAccountName"]
        Add-ADGroupMember $cmGroup -Members $userDefinition["SamAccountName"] 
    }
    elseif($user.AccountType -eq "DomainAdmin")
    {
        Add-ADGroupMember $daGroup -Members $userDefinition["SamAccountName"]  
        Add-ADGroupMember $cmGroup -Members $userDefinition["SamAccountName"]  
    }
    elseif($user.AccountType -eq "ServerAdmin")
    {
        Add-ADGroupMember $saGroup -Members $userDefinition["SamAccountName"] 
    }
    elseif($user.AccountType -eq "WorkstationAdmin")
    {
        Add-ADGroupMember $waGroup -Members $userDefinition["SamAccountName"] 
    }
}