(*
	# DESCRIPTION #
	
	This script "snoozes" the currently selected actions or projects by setting the start date to 
	given number of days in the future.
	
	
	# LICENSE #
	
	Copyright © 2010 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)
	
	
	# CHANGE HISTORY #
	
	0.41 (2011-10-31)
	-	Updated Growl code to work with Growl 1.3 (App Store version)
	-	Updated tell syntax to call "first document window", not "front document window"
	
	0.4 (2011-08-30)
	-	Rewrote notification code to gracefully handle situations where Growl is not installed
	-	Changed "The item/The items" to "It/They"
	
	0.3 (2011-07-07)
	-	New option to set start time (default: 8am)
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
property showSummaryNotification : true --if true, will display success notifications
property defaultOffset : 1 --number of days to snooze by default
property defaultStartTime : 8 --default time to use (in hours, 24-hr clock)

-- Don't change these
property alertItemNum : ""
property alertItemPronoun : "It"
property alertDayNum : ""
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"

on main()
	tell application "OmniFocus"
		tell content of first document window of front document
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
			set todayStart to (current date) - (get time of (current date)) + (defaultStartTime * 3600)
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
		if successTot > 1 then
			set alertItemPronoun to "They"
			set alertItemNum to "s"
		end if
		set alertText to successTot & " item" & alertItemNum & " snoozed. " & alertItemPronoun & " will become available in " & daysOffset & " day" & alertDayNum & "." as string
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

(* Begin notification code *)
on notify(alertName, alertTitle, alertText)
	--Call this to show a normal notification
	my notifyMain(alertName, alertTitle, alertText, false)
end notify

on notifyWithSticky(alertName, alertTitle, alertText)
	--Show a sticky Growl notification
	my notifyMain(alertName, alertTitle, alertText, true)
end notifyWithSticky

on IsGrowlRunning()
	tell application "System Events" to set GrowlRunning to (count of (every process where creator type is "GRRR")) > 0
	return GrowlRunning
end IsGrowlRunning

on dictToString(dict) --needed to encapsulate dictionaries in osascript
	set dictString to "{"
	repeat with i in dict
		if (length of dictString > 1) then set dictString to dictString & ", "
		set dictString to dictString & "\"" & i & "\""
	end repeat
	set dictString to dictString & "}"
	return dictString
end dictToString

on notifyWithGrowl(growlHelperAppName, alertName, alertTitle, alertText, useSticky)
	tell my application growlHelperAppName
		«event register» given «class appl»:growlAppName, «class anot»:allNotifications, «class dnot»:enabledNotifications, «class iapp»:iconApplication
		«event notifygr» given «class name»:alertName, «class titl»:alertTitle, «class appl»:growlAppName, «class desc»:alertText
	end tell
end notifyWithGrowl

on NotifyWithoutGrowl(alertText)
	tell application "OmniFocus" to display dialog alertText with icon 1 buttons {"OK"} default button "OK"
end NotifyWithoutGrowl

on notifyMain(alertName, alertTitle, alertText, useSticky)
	set GrowlRunning to my IsGrowlRunning() --check if Growl is running...
	if not GrowlRunning then --if Growl isn't running...
		set GrowlPath to "" --check to see if Growl is installed...
		try
			tell application "Finder" to tell (application file id "GRRR") to set strGrowlPath to POSIX path of (its container as alias) & name
		end try
		if GrowlPath is not "" then --...try to launch if so...
			do shell script "open " & strGrowlPath & " > /dev/null 2>&1 &"
			delay 0.5
			set GrowlRunning to my IsGrowlRunning()
		end if
	end if
	if GrowlRunning then
		tell application "Finder" to tell (application file id "GRRR") to set growlHelperAppName to name
		notifyWithGrowl(growlHelperAppName, alertName, alertTitle, alertText, useSticky)
	else
		NotifyWithoutGrowl(alertText)
	end if
end notifyMain
(* end notification code *)
main()
