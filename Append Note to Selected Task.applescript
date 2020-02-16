(*
	# DESCRIPTION # 
	
	Appends a note to the selected OmniFocus task(s).
	-	By default, the clipboard contents are used for the note
	-	If triggered from LaunchBar or Alfred, you can specify the text

	See https://github.com/dbyler/omnifocus-scripts for updates


	# LICENSE #

	Copyright © 2015-2020 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)


	# CHANGE HISTORY #

	2020-02-14
	- Purge old Growl code; general cleanups
	
	2017-04-23
	-	Fixes an issue when running with certain top-level category separators selected
	-	Minor update to notification code

	2015-05-17
	-	Fix for attachments being overwritten by the note
	-	Use Notification Center instead of an alert when not running Growl. Requires Mountain Lion or newer
	
	2015-05-09
	-	Original release
*)

property showNotification : true --if true, will display success notifications

on main(q)
	if q is missing value then
		set q to (the clipboard)
	end if
	
	tell application "OmniFocus"
		tell content of first document window of front document
			--Get selection
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder and class of its value is not tag and class of its value is not perspective)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				display notification "No valid task(s) selected" with title "Error"
				return
			end if
			
			if totalItems > 1 then
				display dialog "Multiple items selected. Continue?" buttons {"Cancel", "OK"} default button 2
			end if
			
			repeat with myTask in validSelectedItemsList
				tell myTask
					insert q & "

" at before first paragraph of note
				end tell
				if showNotification then
					set alertTitle to "Note added to " & name of myTask
					set alertText to "\"" & q & "\""
					display notification alertText with title alertTitle
				end if
			end repeat
		end tell
	end tell
end main

main(missing value)

on alfred_script(q)
	main(q)
end alfred_script

on handle_string(q)
	main(q)
end handle_string
