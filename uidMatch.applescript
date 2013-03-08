-- uidMatch v0.4 [Todd McDaniel, mcdan@engin.umich.edu, 3/10/03]

-- This application will allow you to match your local uid to your remote afs uid. Values can also be entered by hand or discovered using local tools.
-- The script will try and keep you from doing something stoopid, but your mileage may vary.
-- A list of the files changed is created in /tmp/uid_match_results_for_{username}

-- Source included.


--Store the current username for later use.
set currentUser to do shell script "whoami" as string

display dialog "Method of user name selection?" buttons {"from list", "by hand", "Cancel"} default button 1 with icon note

if button returned of the result = "from list" then
	--Create list of local users and select from dialog
	set userList to do shell script "nidump passwd . | cut -d: -f1"
	set OldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to return
	set pickList to text items of userList
	set AppleScript's text item delimiters to OldDelims
	set myUniqname to choose from list pickList
	if myUniqname = false then
		display dialog "User cancelled script." buttons {"Exit"} default button 1 with icon stop
		return --Exit script now
	end if
else if button returned of the result = "by hand" then
	display dialog "Enter the username of local user to change: " default answer "uniqname" with icon note
	set myUniqname to the text returned of the result
end if

--Check to make sure user exists, primarily for hand entered user
try
	set tmp_niDump to do shell script "/usr/bin/nidump passwd . | grep " & myUniqname
on error number errnum
	display dialog "Error! No such user! [" & errnum & "]" buttons {"Exit"} default button 1 with icon stop
	return --Exit script now
end try

--Get the users current uid and store for later use	
try
	set tmp_Uid to do shell script "id -u " & myUniqname
on error number errnum
	display dialog "Error! [" & errnum & "]" buttons {"Exit"} default button 1 with icon stop
	return --Exit script now
end try

--Select the method of remote uid selection
display dialog "Choose method of external uid discovery:" buttons {"afs tools", "by hand", "Cancel"} default button 2 with icon note
if button returned of the result = "afs tools" then
	--Get uid from afs tools, checking to make sure they are installed
	try
		do shell script "pts examine " & myUniqname & " -noauth"
		set afsUID to do shell script "pts examine " & myUniqname & " -noauth | grep id | cut -d: -f3 | cut -d\\  -f2 | cut -d, -f1"
		display dialog "remote uid: " & afsUID with icon note
	on error number errnum
		if errnum = 1 then
			display dialog "Error! User not discovered. [" & errnum & "]" buttons {"Exit"} default button 1 with icon stop
			return --Exit script now
		else if errnum = -128 then
			display dialog "User cancelled script." buttons {"Exit"} default button 1 with icon stop
			return --Exit script now
		else
			display dialog "Error! Is OpenAFS installed? [" & errnum & "]" buttons {"Exit"} default button 1 with icon stop
			return --Exit script now
		end if
	end try
	
else if button returned of the result = "by hand" then
	--Get uid from the user, checking to make sure it's an integer
	try
		display dialog "Enter AFS UID: Current ID [" & tmp_Uid & "]" default answer "1000000" with icon note
		set afsUID to the text returned of the result as integer
	on error number errnum
		if errnum = -128 then
			display dialog "User cancelled script." buttons {"Exit"} default button 1 with icon stop
			return --Exit script now		
		else
			display dialog "Not an integer! [" & errnum & "]" buttons {"Exit"} default button 1 with icon stop
			return --Exit script now
		end if
	end try
end if

--Much better way to detect duplicate UIDs
try
	--Get a dump of the local uid list, grep against selected uid.
	--If we get an error, everything should be okay.
	do shell script "nidump passwd . | cut -d: -f3 | grep " & afsUID
	display dialog "This uid [" & afsUID & "] already exists locally!" buttons {"Exit"} default button 1 with icon stop
	return --Exit script now
on error number errnum
	--uid doesn't exist locally, keep going.	
end try

--Assemble and execute the command string.
--The niutil command changed the netinfo directory entry for the user to the new uid.
--The find command will find all of the users files and change ownership to the new uid.
set cmndA to "sudo /usr/bin/niutil -createprop . /users/" & myUniqname & " uid " & afsUID
set cmndB to "/usr/bin/find / -xdev -user " & tmp_Uid & " -exec chown " & myUniqname & " {} \\; -print"
set myCmd to cmndA & "; " & cmndB & " > /tmp/uid_match_results_for_" & myUniqname
try
	display dialog "After you authenticate, this command may take a few minutes. Please be patient..." with icon caution
	do shell script "sh -c " & quoted form of myCmd with administrator privileges
	display dialog "Finished with no apparent errors!" & return & "Output stored in /tmp/uid_match_results_for_" & myUniqname buttons {"Exit"} default button 1 with icon note
on error number errnum
	if errnum = -128 then
		display dialog "User cancelled script." buttons {"Exit"} default button 1 with icon stop
		return --Exit script now
	else
		display dialog "An error has occured! [" & errnum & "]" buttons {"Exit"} default button 1 with icon stop
		return --Exit script now
	end if
end try