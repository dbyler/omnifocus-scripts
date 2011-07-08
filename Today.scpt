(*
	# DESCRIPTION #

	This script takes the currently selected actions or projects and sets them for action today.

	**IMPORTANT: Now has two modes: "Start" mode and "Due" mode. Start mode is for people
	who use start dates to plan for the day; Due mode is for people who use Due dates for the same.
	It is now my opinion that Start dates are more useful for day-to-day planning, but this script is 
	intended to provide flexibility in whatever system you use.
	
	By default, this script will now set start dates, but you can change this in the settings below.**
	
	
	## START MODE LOGIC ##
	For each item:
	-	If there's no existing start date: sets Start Date to today (at time specified in script settings)
	-	If there's an existing start date: sets Start Date to today (at time of original date)
	
	## DUE MODE LOGIC ##
	For each item:
	-	If there's no original due date: sets Due to today at the time listed in the script's settings
		and ignores start date
	-	If there's an original due date: sets Due to today at the *original* due time
	-	If there's an original due date AND start date: sets Due to today at *original* due time
		AND advances Start Date by same # of days as due date
		(this is to respect parameters of repeating actions)
	
	
	# LICENSE #
	
	Copyright © 2011 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php) 
	(TL;DR: do whatever you want with it.)
	

	# CHANGE HISTORY #

	version 0.3 (2011-07-07):
	-	New setting: "Start" or "Due" modes (see above)
	-	No longer fails when a Grouping divider is selected
	-	Streamlined calls to OmniFocus with Rob Trew's input (Thanks, Rob!)
	-	Reorganized script for better readability

	version 0.2c (2010-06-22)
	-	Actual fix for autosave

	version 0.2b (2010-06-21)
	-	Encapsulated autosave in "try" statements in case this fails

	version 0.2 (2010-06-15)
	-	Added performance optimization (thanks to Curt Clifton)
	-	Fixed Growl code (broke with Snow Leopard)
	-	Switched to MIT license (simpler, less restrictive)

	version 0.1: Initial release. Based on my Defer script, which incorporates bug fixes from Curt Clifton. Also uses method that doesn't call Growl directly. This code should be friendly for machines that don't have Growl installed. In my testing, I found that GrowlHelperApp crashes on nearly 10% of AppleScript calls, so the script checks for GrowlHelperApp and launches it if not running. (Thanks to Nanovivid from forums.cocoaforge.com/viewtopic.php?p=32584 and Macfaninpdx from forums.macrumors.com/showthread.php?t=423718 for the information needed to get this working

	# INSTALLATION #

	-	Copy to ~/Library/Scripts/Applications/Omnifocus
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

	# KNOWN BUGS #
	- When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus returns an error. This issue does not occur when invoked from the script menu, a Quicksilver trigger, etc.
		
*)

-- To change settings, modify the following properties

--The following setting changes script mode. Options: "start" or "due" (quotes needed)
property mode : "start"

property showSummaryNotification : false --if true, will display success notifications
property useGrowl : true --if true, will use Growl for success/failure alerts
property startTime : 6 --Start hour for items not previously assigned a start time (24 hr clock)
property dueTime : 17 --Due hour for items not previously assigned a due time (24 hr clock)

-- Don't change these
property alertItemNum : ""
property alertDayNum : ""
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"

on main()
	tell application "OmniFocus"
		tell content of front document window of front document
			--Get selection
			set totalMinutes to 0
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				my notify(alertName, alertTitle, alertText)
				return
			end if
			
			--Perform action
			set successTot to 0
			set autosave to false
			set currDate to (current date) - (time of (current date))
			if mode is "start" then
				repeat with thisItem in validSelectedItemsList
					set succeeded to my startToday(thisItem, currDate)
					if succeeded then set successTot to successTot + 1
				end repeat
			else if mode is "due" then
				repeat with thisItem in validSelectedItemsList
					set succeeded to my dueToday(thisItem, currDate)
					if succeeded then set successTot to successTot + 1
				end repeat
			else
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "Improper mode setting"
				my notify(alertName, alertTitle, alertText)
			end if
			set autosave to true
		end tell
	end tell
	
	--Display summary notification
	if showSummaryNotification then
		set alertName to "General"
		set alertTitle to "Script complete"
		if successTot > 1 then set alertItemNum to "s"
		set alertText to successTot & " item" & alertItemNum & " now due today." as string
		my notify(alertName, alertTitle, alertText)
	end if
end main

on startToday(selectedItem, currDate)
	set success to false
	tell application "OmniFocus"
		try
			set originalStartDateTime to start date of selectedItem
			if (originalStartDateTime is not missing value) then
				--Set new start date with original start time
				set start date of selectedItem to (currDate + (time of originalStartDateTime))
				set success to true
			else
				set start date of selectedItem to (currDate + (startTime * hours))
				set success to true
			end if
		end try
	end tell
	return success
end startToday

on dueToday(selectedItem, currDate)
	set success to false
	tell application "OmniFocus"
		try
			set originalDueDateTime to due date of selectedItem
			if (originalDueDateTime is not missing value) then
				--Set new due date with original due time
				set originalDueStartDate to originalDueDateTime - (time of originalDueDateTime)
				set theDelta to (currDate - originalDueStartDate) / 86400
				set newDueDateTime to (originalDueDateTime + (theDelta * days))
				set due date of selectedItem to newDueDateTime
				set originalStartDateTime to start date of selectedItem
				if (originalStartDateTime is not missing value) then
					set newStartDateTime to (originalStartDateTime + (theDelta * days))
					set start date of selectedItem to newStartDateTime
				end if
				set success to true
			else
				set due date of selectedItem to (currDate + (dueTime * hours))
				set success to true
			end if
		end try
	end tell
	return success
end dueToday

on notify(alertName, alertTitle, alertText)
	if useGrowl then
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

main()