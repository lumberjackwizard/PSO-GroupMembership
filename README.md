Powershell script created to list the virtual machines that comprise NSX groups. The script will request the nsx manager IP/FQDN, username, and password, which will result in a menu where you'll be prompted with 2 choices: 

1.  Enter a specific group for which you want the VM membership or
2.  Obtain the VM memberhips of all user created groups

Notes:

The script itself will gather up a list of all groups available in the local NSX manager, excluding any groups that are created by the 'system' entity (as the intent of this script is to gather the VM membership of user created groups specifically.)

Option 1 prompts you to enter the group name for which you want the membership. You may enter the first part of the name, and the script will match against any group that begins with what has been entered. For instance, entering "wordpress" would match against groups named "wordpress", "wordpress_app", "wordpressweb" or "wordpress123". 

If there's no match for the name entered, you will be notifed and be returned to the main menu, where you may try again. If you exit from the program at this point, no file will be generated. 

Option 2 will gather up all groups and their VM membership (provided the group is not system created.) 


Either option will output matching data to a CSV file named "groupoutput.csv" in the directory from where the script was ran. If there is already an existing "groupoutput.csv" file in the directory, it will be fully overwritten. 

If either option 1 or 2 are succesfully ran, executing Option 1 or 2 again will result in overwriting the existing groupoutput.csv file. 
