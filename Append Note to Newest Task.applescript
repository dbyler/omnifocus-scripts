(*
	# DESCRIPTION #
	
	Adds a note to the most recently created task in OmniFocus.
	-	By default, the clipboard contents are used for the note
	-	If triggered from LaunchBar or Alfred, you can use different text

	See https://github.com/dbyler/omnifocus-scripts for updates


	# LICENSE #

	Copyright © 2015-2020 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)


	# CHANGE HISTORY #
	
	2020-02-14
	- Purge old Growl code; general cleanups
	
	2017-04-22
	-	Minor update to notification code

	2015-05-17
	-	Fix for attachments being overwritten by the note
	-	Use Notification Center instead of an alert when not running Growl. Requires Mountain Lion or newer
	
	2015-05-09 Original release
*)

property showNotification : true --if true, will display success notifications

on main(q)
	if q is missing value then
		set q to (the clipboard)
	end if
	tell application "OmniFocus"
		tell front document
			set myTask to my getLastAddedTask()
			if myTask is false then
				my notify("Error", "Error", "No recent items available")
				return
			end if
			tell myTask
				insert q & "

" at before first paragraph of note
			end tell
			
			if showNotification then
				set alertTitle to "Note added to " & name of myTask
				set alertText to "\"" & q & "\""
				display notification alertText with title alertTitle
			end if
			
		end tell
	end tell
end main

on getLastAddedTask()
	tell application "OmniFocus"
		tell front document
			set allTasks to {}
			set maxAge to 8
			repeat while length of allTasks is 0 and maxAge ² 524288
				set maxAge to maxAge * 2
				set earliestTime to (current date) - maxAge * 60
				set allTasks to (every flattened task whose (creation date is greater than earliestTime Â
					and repetition is missing value))
			end repeat
			if length of allTasks > 0 then
				set lastTask to first item of allTasks
				set lastTaskDate to creation date of lastTask
				repeat with i from 1 to length of allTasks
					if creation date of (item i of allTasks) > lastTaskDate then
						set lastTask to (item i of allTasks)
						set lastTaskDate to creation date of lastTask
					end if
				end repeat
				return lastTask
			else
				return false
			end if
		end tell
	end tell
end getLastAddedTask

main(missing value)

on alfred_script(q)
	main(q)
end alfred_script

on handle_string(q)
	main(q)
end handle_string
