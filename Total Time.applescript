(*
	# DESCRIPTION #
	Displays the total estimated time of currently selected actions or projects.
	
	# INSTALLATION #
	-	Copy to ~/Library/Application Scripts/com.omnigroup.OmniFocus3
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus
		
*)

on main()
	tell application "OmniFocus"
		tell content of first document window of front document
			--Get selection
			set totalMinutes to 0
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder and class of its value is not tag and class of its value is not perspective)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				my notify(alertName, alertTitle, alertText)
				return
			end if
			
			--Perform action
			repeat with thisItem in validSelectedItemsList
				set thisEstimate to estimated minutes of thisItem
				if thisEstimate is not missing value then set totalMinutes to totalMinutes + thisEstimate
			end repeat
			set modMinutes to (totalMinutes mod 60)
			set totalHours to (totalMinutes div 60)
		end tell
	end tell
	
	--Show summary notification
	if totalItems is 1 then
		set itemSuffix to ""
	else
		set itemSuffix to "s"
	end if
	set alertName to "General"
	set alertTitle to "Script complete"
	set alertText to totalHours & "h " & modMinutes & "m total for " & totalItems & " item" & itemSuffix as string
	my notify(alertName, alertTitle, alertText)
end main

on notify(alertName, alertTitle, alertText)
	display notification alertText with title alertTitle
end notify

main()
