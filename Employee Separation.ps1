#Ask technician for the username of the person leaving

Write-Host "Welcome to the new offboarding Powershell Script! There are a couple questions first." -ForegroundColor Green
$username = Read-Host -Prompt "Enter the username of the employee that's leaving"
$dept = Read-Host -Prompt "Enter the two letter abbreviation for their department ex. IT"
$leavedate = Read-Host -Prompt "When are they leaving? ex. 3-24-2022"

#Grab information from AD

$ADInfo = Get-ADUser -Identity $username

#Create folder in location where you store separation info

New-Item -Path \\**INSERT PATH HERE**\$($ADInfo.Surname)_$($ADInfo.GivenName)_$($Dept)_$($leavedate) -ItemType Directory

#Export user groups

Get-ADPrincipalGroupMembership -Identity $username | select name, groupcategory, groupscope | sort-object name | Export-csv -Path \\**INSERT PATH HERE**\_AD_UserGroupLists\$($ADInfo.Surname)_$($ADInfo.GivenName)_$($Dept)_GroupMemberships.csv
Get-ADPrincipalGroupMembership -Identity $username | select name, groupcategory, groupscope | sort-object name | Export-csv -Path \\**INSERT PATH HERE**\$($ADInfo.Surname)_$($ADInfo.GivenName)_$($Dept)_$($leavedate)\$($ADInfo.Surname)_$($ADInfo.GivenName)_$($Dept)_GroupMemberships.csv

#Reset account password to generic one

Set-ADAccountPassword -Identity $username -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "****PUT PASSWORD HERE****" -Force)

#Disable AD account

Disable-ADAccount -Identity $username

#Clear AD proxy addresses

Set-ADUser -Identity $username -Clear ProxyAddresses

#Add single AD proxy address

Set-ADUser -Identity $username -add @{ProxyAddresses="SMTP:DisabledUser_$username@**********.com"}

#Change mail AD address

Set-ADUser -Identity $username -Replace @{mail="DisabledUser_$username@**********.com"}

#Change target AD address

Set-ADUser -Identity $username -Replace @{targetAddress="SMTP:DisabledUser_$username@**********.com"}

#Clear AD phone number field

Set-ADUser -Identity $username -Clear telephoneNumber

#Remove all AD group memberships from AD except for Domain Users

$groups = Get-ADPrincipalGroupMembership $username |
    Where Name -notlike 'Domain Users'
Remove-ADPrincipalGroupMembership -Identity $username -MemberOf $groups

#Check off hide from address lists on Casper

Set-ADObject $ADInfo.DistinguishedName -replace @{msExchHideFromAddressLists=$true}
Set-ADObject $ADInfo.DistinguishedName -clear ShowinAddressBook

#Move user to new disabled OU depending on department

if ( $dept -eq "IT" )
{
    Move-ADObject -Identity $ADInfo.DistinguishedName -TargetPath "***INSERT OU HERE***"
}
