# Temporarily hard setting nsxmgr and credentials for development. Get-Credential will be used in the future. 
# Requires PowerCLI. This was tested using version 11.x. This or any newer version should work. 

$nsxmgr = '172.16.10.11'
$nsxuser = 'admin'
$nsxpasswd = ConvertTo-SecureString -String 'VMware1!VMware1!' -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $nsxuser, $nsxpasswd

#$nsxmgr = Read-Host "Enter NSX Manager IP or FQDN"
#$Cred = Get-Credential -Title 'NSX Manager Credentials' -Message 'Enter NSX Username and Password'

# Uri will get only groups under infra, and the result is stored in $rawpolicy

$Uri = 'https://'+$nsxmgr+'/policy/api/v1/infra?type_filter=Group'

$rawpolicy = Invoke-RestMethod -Uri $Uri -SkipCertificateCheck -Authentication Basic -Credential $Cred 



function Get-All-Group-Members{
    $groupCSV = "Group Name, Group Member VMs `n"
    foreach ($group in $rawpolicy.children.Domain.children.Group | Where-object {$_._create_user -ne "system"}){
       
        
        $groupid = $group.id
        
        $groupVMmemberURI = 'https://'+$nsxmgr+'/policy/api/v1/infra/domains/default/groups/'+$groupid+'/members/virtual-machines'
        $groupVmMembers = Invoke-RestMethod -Uri $groupVMmemberURI -SkipCertificateCheck -Authentication Basic -Credential $Cred

    
        $groupName = $group.display_name



        $groupVmMemberNames = ($groupVmMembers.results  | ForEach-Object { $_.display_name } | Sort-Object {if ($_ -match '\d+$') { [int]$matches[0] } else { $_}})-join "; "

        $groupCSV += "$groupName,$groupVmMemberNames `n"
        

    }
    return $groupCSV
}

Function Get-Target-Group-Members{
    $groupCSV = "Group Name, Group Member VMs `n"
    #using a -like for display_name match and appending it with an * for wildcarding
    #this way users can just get the beginning of a group name correctly and all matches will get pulled
    foreach ($group in $rawpolicy.children.Domain.children.Group | Where-object {$_.display_name -like $target+"*"}){
       Write-Host "Match found for:" $group.display_name 
        $groupid = $group.id
        
        $groupVMmemberURI = 'https://'+$nsxmgr+'/policy/api/v1/infra/domains/default/groups/'+$groupid+'/members/virtual-machines'
        $groupVmMembers = Invoke-RestMethod -Uri $groupVMmemberURI -SkipCertificateCheck -Authentication Basic -Credential $Cred

    
        $groupName = $group.display_name



        $groupVmMemberNames = ($groupVmMembers.results  | ForEach-Object { $_.display_name } | Sort-Object {if ($_ -match '\d+$') { [int]$matches[0] } else { $_}})-join "; "

        $groupCSV += "$groupName,$groupVmMemberNames `n"
        

    }
    return $groupCSV
}

function Show-Menu
{
     param (
           [string]$Title = ‘Gather NSX Group Memberships’
     )
     cls
     Write-Host “================ $Title ================”
     
     Write-Host “1: Press ‘1’ for a specific NSX Group and it's Membership”
     Write-Host “2: Press ‘2’ for all NSX Groups and Memberships”
     Write-Host “q: Press ‘q’ to quit”
}

# Main

do
{
     Show-Menu
     $input = Read-Host “Please make a selection”
     switch ($input)
     {
           ‘1’ {
                cls
                $target = Read-Host "Enter target NSX Group name"
				$groupCSV = Get-Target-Group-Members
                # Split the CSV by line breaks
                $lines = $groupCSV -split "`n"
                # Check if there is only the header line
                # using an -eq of 2 since i've inserted a newline in the csv header line
                # this means that even with no matches, $lines will break into 2 entries:
                # one is the header line for the cvs, and the other line is blank
                if ($lines.Count -eq 2) {
                    Write-Host "There were no matches for: $target."
                } else {
                # Output $groupCSV to the file
                $groupCSV | Out-File -FilePath "./groupoutput.csv" -Encoding UTF8
                'Done! Data output to "groupoutput.csv" in directory where this script was executed'
                }
                
				
           } ‘2’ {
                cls
                ‘Gathering All NSX Groups and Memberships...’
				$groupCSV = Get-All-Group-Members
                # Output $groupCSV to the file
                $groupCSV | Out-File -FilePath "./groupoutput.csv" -Encoding UTF8
				'Done! Data output to "groupoutput.csv" in directory where this script was executed'
           } ‘q’ {
                return
           }
     }
     pause
}
until ($input -eq ‘q’)



