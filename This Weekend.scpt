(*
	# DESCRIPTION #
	
	This script takes the currently selected actions or projects and sets them for action this weekend.
	(If a weekend is currently in progress, the items will be set for the *current* weekend.)
	
	**IMPORTANT: The script will now always set a start date. Whether it sets a due date is up to you.
	Change this setting with the setDueDate property below.**
	
	The dates and times are set by variables, so you can modify to meet your weekend.
	
	# LICENSE #

	Copyright © 2010 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	

	# CHANGE HISTORY #
	
	0.2 (2011-07-07)
	-	Setting a due date is now optional (see settings below)
	-	No longer fails when a Grouping divider is selected
	-	Reorganized; incorporated Rob Trew's method to get items from OmniFocus
	-	Fixes potential issue when launching from OmniFocus toolbar

	0.1c (2010-06-22)
		-	Actual fix for autosave

	0.1b (2010-06-21)
		-	Encapsulated autosave in "try" statements in case this fails

	0.1: Initial release. Based on my Defer script, which incorporates bug fixes from Curt Clifton. By default, notifications are disabled (uncomment the appropriate lines to enable them).


	# INSTALLATION #

	1. Copy to ~/Library/Scripts/Applications/Omnifocus
 	2. If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

	# KNOWN BUGS #
	
	- When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus returns an error. This issue does not occur when invoked from the script menu, a Quicksilver trigger, etc.
		
*)

-- To change your weekend start/stop date/time, modify the following properties
property setDueDate : true --set to False if you don't want to change the due date
property weEndDay : Sunday
property weEndTime : 17 --due time in hours (24 hr clock)
property weStartDay : Friday
property weStartTime : 20 --due time in hrs (24 hr clock)

--To enable alerts, change these settings to True _and_ uncomment
property showSummaryNotification : false --if true, will display success notifications
property useGrowl : true --if true, will use Growl for success/failure alerts

-- Don't change these
property alertItemNum : ""
property alertDayNum : ""
property dueDate : ""
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"

on main()
	tell application "OmniFocus"
		tell content of front document window of front document
			--Get selection
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				my notify(alertName, alertTitle, alertText)
				return
			end if
			
			--Calculate due date
			set dueDate to current date
			set theTime to time of dueDate
			repeat while weekday of dueDate is not weEndDay
				set dueDate to dueDate + 1 * days
			end repeat
			set dueDate to dueDate - theTime + weEndTime * hours
			--set dueDate to dueDate + 1 * weeks --uncomment to use _next_ weekend instead
			
			--Calculate start date
			set diff to weEndDay - weStartDay
			if diff < 0 then set diff to diff + 7
			set diff to diff * days + (weEndTime - weStartTime) * hours
			set startDate to dueDate - diff
			
			--Perform action
			set successTot to 0
			set autosave to false
			repeat with thisItem in validSelectedItemsList
				set succeeded to my setDate(thisItem, startDate, dueDate)
				if succeeded then set successTot to successTot + 1
			end repeat
			set autosave to true
		end tell
	end tell
	
	--Display summary notification
	if showSummaryNotification then
		if successTot > 1 then set alertItemNum to "s"
		set alertText to successTot & " item" & alertItemNum & " now due this weekend." as string
		my notify("General", "Script complete", alertText)
	end if
end main

on setDate(selectedItem, startDate, dueDate)
	set success to false
	tell application "OmniFocus"
		try
			set start date of selectedItem to startDate
			if setDueDate then set due date of selectedItem to dueDate
			set success to true
		end try
	end tell
	return success
end setDate

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