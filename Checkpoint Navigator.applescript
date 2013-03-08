-- Checkpoint Navigator v0.4 [Todd McDaniel, mcdan@engin.umich.edu, 11/11/05]
-- Allow user to navigate SAN checkpoint backups.
-- Source included.

-- ttd:
-- add cancellation  reporting.
-- fail with useful dialog.
-- purge unused variables --Are there any?



set monthList to {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
set dayList to {"31", "28", "31", "30", "31", "30", "31", "31", "30", "31", "30", "31"}
set dayNameList to {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
set myModCheckPointList to {}
set myCheckPointPath to "/Volumes/home/.ckpt"

--get date and populate variables
set myDateTodayDay to (do shell script "date \"+%e\"") as integer
set myDateTodayMonth to do shell script "date \"+%B\""
set myDateTodayYear to (do shell script "date \"+%Y\"") as integer
set myYesterdayMonth to ""

--leap year calculations
if (myDateTodayYear mod 4) = 0 then
	if (myDateTodayYear mod 100) = 0 then
		if (myDateTodayYear mod 400) = 0 then
			set myLeapYear to true
		else
			set myLeapYear to false
		end if
	else
		set myLeapYear to true
	end if
else
	set myLeapYear to false
end if

if myDateTodayDay = 1 then -- beginning of month
	if myDateTodayMonth = 1 then --beginning of year
		set myYesterdayDay to 31
		set myYesterdayMonth to 12
	else -- beginning of month, not beginning of year
		set myYesterdayMonth to myDateTodayMonth - 1
		set myYesterdayDay to (item myYesterdayMonth of dayList)
		if (myLeapYear = true) and (myDateTodayMonth = 3) then set myYesterdayDay to 29
	end if
else -- not beginning of month
	set myYesterdayDay to myDateTodayDay - 1
end if

--why are there two setters?
--set text item delimiters to ","
set text item delimiters to return

--Check if NAS is mounted
try
	do shell script "test -d " & myCheckPointPath
on error
	display dialog "No checkpoints found." & return & "Is the NAS mounted?" buttons {"Exit"} default button 1 with icon stop
	return --Exit script now
end try

--get list of available checkpoints
set myCheckPoints to do shell script "ls " & myCheckPointPath

set myCheckPointList to text items of myCheckPoints

--parse list of available checkpoints and reformat into readable dates
repeat with i from 1 to the count of myCheckPointList
	set thisItem to (item i of myCheckPointList)
	set the text item delimiters to "_"
	set myItem to text items of thisItem
	set myYear to item 1 of myItem
	set myMonth to item 2 of myItem as integer
	set myMonthName to item myMonth of monthList
	set myDay to item 3 of myItem as integer
	set myTime to item 4 of myItem
	set myZone to item 5 of myItem
	
	set the text item delimiters to "."
	set myTimeElements to text items of myTime
	set myTimeHour to text item 1 of myTimeElements as integer
	set myTimeMinute to text item 2 of myTimeElements
	if myTimeHour > 12 then
		set myModHour to myTimeHour - 12
		set myModZone to "pm"
	else
		set myModHour to myTimeHour as string
		set myModZone to "am"
	end if
	
	if myDay = myDateTodayDay then
		set MyModDay to "Today"
	else if myDay = myYesterdayDay then
		set MyModDay to "Yesterday"
	else
		set MyModDay to myMonthName & " " & myDay & ", " & myYear
	end if
	
	set myModCheckPoint to MyModDay & ", " & myModHour & ":" & myTimeMinute & " " & myModZone
	
	set myModCheckPointList to myModCheckPointList & {myModCheckPoint}
	
end repeat

set mySelection to choose from list myModCheckPointList with prompt "Please select the checkpoint to examine:"

--attempt to open selected checkpoint
if mySelection is not false then
	repeat with i from 1 to the count of myModCheckPointList
		if (item i of myModCheckPointList) is (mySelection as string) then set mySelectionIndex to i
	end repeat
	try
		tell application "Finder"
			do shell script "open " & myCheckPointPath & "/" & item mySelectionIndex of myCheckPointList
		end tell
	on error number errnum
		display dialog "An error has occured! [# " & errnum & "]" & return & "I was trying to open the checkpoint." buttons {"Exit"} default button 1 with icon stop giving up after 1
		return --Exit script now
	end try
else
	display dialog "User cancelled script." buttons {"Exit"} default button 1 with icon stop
	return --Exit script now
end if