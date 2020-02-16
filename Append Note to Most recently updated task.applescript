(*
	# DESCRIPTION #
	
	Appends a note to the most recently modified task in OmniFocus.
	-	By default, the clipboard contents are used for the note
	-	If triggered from LaunchBar or Alfred, you can use different text

	See https://github.com/dbyler/omnifocus-scripts for updates


	# LICENSE #

	Copyright © 2015-2020 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)


	# CHANGE HISTORY #
	
	2020-02-16
	-	Update notification message; finish purging Growl code
	
	2019-07-16
	-	First release (based on Append note to Newest Task)
	
	Note to self: see comment on line 82. This may be brittle and require a different fix
	
*)


-- To change settings, modify the following properties
property showSummaryNotification : true --if true, will display success notifications

on main(q)
	if q is missing value then
		set q to (the clipboard)
	end if
	tell application "OmniFocus"
		tell front document
			set myTask to my getLastModifiedTask()
			if myTask is false then
				display notification "No recent items available" with title "Error"
				return
			end if
			tell myTask
				insert q & "

" at before first paragraph of note
			end tell
			if showSummaryNotification then
				set alertTitle to "Note added to " & name of myTask
				set alertText to "\"" & q & "\""
				display notification alertText with title alertTitle
			end if
		end tell
	end tell
end main

on getLastModifiedTask()
	tell application "OmniFocus"
		tell front document
			set allTasks to {}
			set maxAge to 8
			repeat while length of allTasks is 0 and maxAge ≤ 524288
				set maxAge to maxAge * 2
				set earliestTime to (current date) - maxAge * 60
				set allTasks to (every flattened task whose (modification date is greater than earliestTime ¬
					and repetition is missing value))
			end repeat
			if length of allTasks > 0 then
				set lastTask to first item of allTasks
				set lastTaskDate to modification date of lastTask
				repeat with i from 1 to length of allTasks
					if modification date of (item i of allTasks) ≥ lastTaskDate then --a task's root task, if present, will have the same modification date as the task, but seems to appear first in the list, so this should pull the task
						set lastTask to (item i of allTasks)
						set lastTaskDate to modification date of lastTask
					end if
				end repeat
				return lastTask
			else
				return false
			end if
		end tell
	end tell
end getLastModifiedTask

on notify(alertName, alertTitle, alertText)
	display notification alertText with title alertTitle
end notify

main(missing value)

on alfred_script(q)
	main(q)
end alfred_script

on handle_string(q)
	main(q)
end handle_string
