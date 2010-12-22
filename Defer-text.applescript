(*
	# Description #
	
	This script takes the currently selected actions or projects and defers, or "snoozes", them by the user-specified number of days.
	The user may snooze just the due date or both the start and due dates (useful for skipping weekends for daily recurring tasks).
	
	
	# License #

	Copyright © 2008-2010 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)

	
	# Version history #
	
	0.3c (2010-06-21)
		-	Actual fix for autosave
	
	0.3b (2010-06-21)
		-	Encapsulated autosave in "try" statements in case this fails
	
	0.3 (2010-06-15)
		-	Incorporated another improvement from Curt Clifton to increase performance
		-	Reinstated original Growl code since the Growl-agnostic code broke in Snow Leopard
	
	0.2
		-	Incorporated Curt Clifton's bug fixes to make script more reliable when dealing with multiple items. Thanks, Curt!
		-	Added some error suppression to deal with deferring from Context mode
		-	Defers both start and due dates by default.
		-	Incorporates new method that doesn't call Growl directly. This code should be friendly for machines that don't have Growl installed. In my testing, I found that GrowlHelperApp crashes on nearly 10% of AppleScript calls, so the script checks for GrowlHelperApp and launches it if not running. (Thanks to Nanovivid from forums.cocoaforge.com/viewtopic.php?p=32584 and Macfaninpdx from forums.macrumors.com/showthread.php?t=423718 for the information needed to get this working
		-	All that said... if you run from the toolbar frequently, I'd recommend  turning alerts off since Growl slows down the script so much
		
	0.1: Original release


	# Installation #

	-	Copy to ~/Library/Scripts/Applications/Omnifocus
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

	# Known bugs #
		• When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus returns an error. This issue does not occur when invoked from the script menu, a Quicksilver trigger, etc.
		
	To do:
		- Optimize Growl notification so it runs in the background

*)

property showAlert : false --if true, will display success/failure alerts
property useGrowl : true --if true, will use Growl for success/failure alerts
property defaultSnooze : 1 --number of days to defer by default
property alertItemNum : ""
property alertDayNum : ""
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"


tell application "OmniFocus"
	tell front document
		tell (first document window whose index is 1)
			set theSelectedItems to selected trees of content
			set numItems to (count items of theSelectedItems)
			if numItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				my notify(alertName, alertTitle, alertText)
				return
			end if
			
			display dialog "Defer for how many days?" default answer defaultSnooze buttons {"Cancel", "OK"} default button 2
			(* if (the button returned of the result) is not "OK" then
				return
			end if  *)
			set snoozeLength to (the text returned of the result) as integer
			if snoozeLength is not 1 then
				set alertDayNum to "s"
			end if
			set changeScopeQuery to display dialog "Modify start and due dates?" buttons {"Cancel", "Due Only", "Start and Due"} default button 3 with icon caution giving up after 60
			set changeScope to button returned of changeScopeQuery
			if changeScope is "Cancel" then
				return
			else if changeScope is "Start and Due" then
				set modifyStartDate to true
			else if changeScope is "Due Only" then
				set modifyStartDate to false
			end if
			set selectNum to numItems
			set successTot to 0
			set autosave to false
			repeat while selectNum > 0
				set selectedItem to value of item selectNum of theSelectedItems
				set succeeded to my defer(selectedItem, snoozeLength, modifyStartDate)
				if succeeded then set successTot to successTot + 1
				set selectNum to selectNum - 1
			end repeat
			set autosave to true
			set alertName to "General"
			set alertTitle to "Script complete"
			if successTot > 1 then set alertItemNum to "s"
			set alertText to successTot & " item" & alertItemNum & " deferred " & snoozeLength & " day" & alertDayNum & ". (" & changeScope & ")" as string
		end tell
	end tell
	my notify(alertName, alertTitle, alertText)
end tell

on defer(selectedItem, snoozeLength, modifyStartDate)
	set success to false
	tell application "OmniFocus"
		try
			set theDueDate to due date of selectedItem
			if (theDueDate is not missing value) then
				set newDue to (theDueDate + (86400 * snoozeLength))
				set due date of selectedItem to newDue
				set success to true
			end if
			if modifyStartDate is true then
				set theStartDate to start date of selectedItem
				if (theStartDate is not missing value) then
					set newStart to (theStartDate + (86400 * snoozeLength))
					set start date of selectedItem to newStart
					set success to true
				end if
			end if
		end try
	end tell
	return success
end defer


on notify(alertName, alertTitle, alertText)
	if showAlert is false then
		return
	else if useGrowl is true then
		--check to make sure Growl is running
		tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		if GrowlRunning = 0 then
			--try to activate Growl
			try
				do shell script "/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
				do shell script "~/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
			end try
			delay 0.2
			tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		end if
		--notify
		if GrowlRunning ≥ 1 then
			try
				tell application "GrowlHelperApp"
					register as application growlAppName all notifications allNotifications default notifications allNotifications icon of application iconApplication
					notify with name alertName title alertTitle application name growlAppName description alertText
				end tell
			end try
		else
			set alertText to alertText & " 
 
p.s. Don't worry—the Growl notification failed but the script was successful."
			display dialog alertText with icon 1
		end if
	else
		display dialog alertText with icon 1
	end if
end notify
