(*
	# DESCRIPTION #
	
	This script "snoozes" the currently selected actions or projects by setting the start date to given number of days in the future.
	
	
	# LICENSE #
	
	Copyright © 2010 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)
	
	
	# CHANGE HISTORY #
	
	0.3 (2011-07-07)
	-	Reorganized; incorporated Rob Trew's method to get items from OmniFocus
	-	No longer fails when a Grouping divider is selected
	-	Fixes potential issue when launching from OmniFocus toolbar
	
	0.2c (2010-06-22)
	-	Actual fix for autosave
	
	0.2b (2010-06-21)
	-	Encapsulated autosave in "try" statements in case this fails
	
	0.2 (2010-06-15)
	-	Fixed Growl code
	-	Added performance optimization (thanks, Curt Clifton)
	-	Changed from LGPL to MIT license (MIT is less restrictive)
		
	0.1: Original release. (Thanks to Curt Clifton, Nanovivid, and Macfaninpdx for various pieces of code)

	
	# INSTALLATION #
	
	-	Copy to ~/Library/Scripts/Applications/Omnifocus
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

	
	# KNOWN ISSUES #
	-	When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus displays an alert.
		This does not occur when invoked from another launcher (script menu, FastScripts LaunchBar, etc).
		
*)

-- To change settings, modify the following properties
property showSummaryNotification : false --if true, will display success notifications
property useGrowl : true --if true, will use Growl for success/failure alerts
property defaultOffset : 1 --number of days to snooze by default

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
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				my notify(alertName, alertTitle, alertText)
				return
			end if
			
			--User options				
			display dialog "Snooze for how many days (from today)?" default answer defaultOffset buttons {"Cancel", "OK"} default button 2
			set daysOffset to (the text returned of the result) as integer
			
			--Perform action
			set todayStart to (current date) - (get time of (current date))
			set successTot to 0
			set autosave to false
			repeat with thisItem in validSelectedItemsList
				set succeeded to my snooze(thisItem, todayStart, daysOffset)
				if succeeded then set successTot to successTot + 1
			end repeat
			set autosave to true
		end tell
	end tell
	
	--Display summary notification
	if showSummaryNotification then
		set alertName to "General"
		set alertTitle to "Script complete"
		if daysOffset is not 1 then set alertDayNum to "s"
		if successTot > 1 then set alertItemNum to "s"
		set alertText to successTot & " item" & alertItemNum & " snoozed. The item" & alertItemNum & " will become available in " & daysOffset & " day" & alertDayNum & "." as string
		my notify(alertName, alertTitle, alertText)
	end if
end main

on snooze(selectedItem, todayStart, daysOffset)
	set success to false
	tell application "OmniFocus"
		try
			set start date of selectedItem to my offsetDateByDays(todayStart, daysOffset)
			set success to true
		end try
	end tell
	return success
end snooze

on offsetDateByDays(myDate, daysOffset)
	return myDate + (86400 * daysOffset)
end offsetDateByDays

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
