(*
	# DESCRIPTION #
	
	Sets the start date of selected items to the specified # of days in the future *from now*.
	Snoozes from current time if a fraction/decimal is given.
	
	
	# LICENSE #
	
	Copyright © 2010-2017 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)
	
	
	# CHANGE HISTORY #
	
	2017-04-23
	-	Fixes an issue when running with certain top-level category separators selected
	-	Minor update to notification code

	0.5.1 (2015-05-17)
	-	Use Notification Center instead of an alert when not running Growl. Requires Mountain Lion or newer
	
	0.5 (2015-05-07)
	-	Support passing # of days through LaunchBar and Alfred (unsupported)
	-	Support snoozing for a fraction of a day. You can use decimals (.01 days is about 15 minutes)
		or fractions (1/24 = 1 hour)	
	-	Shout out to Bill Palmer for an elegant way to snooze without counting seconds in a day
	
	0.4.1 (2011-10-31)
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
	
	0.2.2 (2010-06-22)
	-	Actual fix for autosave
	
	0.2.1 (2010-06-21)
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
property defaultStartTime : 6 --default time to use (in hours, 24-hr clock)

-- Don't change these
property alertItemNum : ""
property alertItemPronoun : "It"
property alertDayNum : ""
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"

on main(q)
	tell application "OmniFocus"
		tell content of first document window of front document
			--Get selection
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder and class of its value is not context and class of its value is not perspective)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				my notify(alertName, alertTitle, alertText)
				return
			end if
			
			--User options
			set res to q
			if res is missing value then
				display dialog "Snooze for how many days (from today)?" default answer defaultOffset buttons {"Cancel", "OK"} default button 2
				set res to (the text returned of the result)
			end if
			try
				set daysOffset to res as integer
				if daysOffset as real is not res as real then
					set daysOffset to res as real
				end if
			on error
				try
					set daysOffset to (run script res) as real
				on error
					set alertName to "Error"
					set alertTitle to "Error"
					set alertText to "Error interpreting your input. Please try an integer or fraction"
					my notify(alertName, alertTitle, alertText)
					return
				end try
			end try
			
			--Perform action
			set successTot to 0
			set autosave to false
			repeat with thisItem in validSelectedItemsList
				set succeeded to my snooze(thisItem, daysOffset)
				if succeeded then set successTot to successTot + 1
			end repeat
			set autosave to true
		end tell
	end tell
	
	--Error notification
	if successTot = 0 then
		my notify("Error", "Error", "No items snoozed")
		return
	end if
	
	--Summary notification
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

on snooze(selectedItem, snoozeLength)
	set success to false
	tell application "OmniFocus"
		try
			set todayMidnight to (current date) - (time of (current date))
			
			if snoozeLength > 0 and snoozeLength < 1.0 then --fractional snooze time
				set defer date of selectedItem to (current date) + (days * snoozeLength)
			else --standard snooze time
				if defer date of selectedItem is not missing value then
					set existingDeferDate to defer date of selectedItem
					set defer date of selectedItem to todayMidnight + (time of existingDeferDate) + (snoozeLength * days)
				else
					set defer date of selectedItem to todayMidnight + (defaultStartTime * hours) + (snoozeLength * days)
				end if
			end if
			set success to true
		end try
	end tell
	return success
end snooze


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

on notifyWithGrowl(growlHelperAppName, alertName, alertTitle, alertText, useSticky)
	tell my application growlHelperAppName
		Çevent registerÈ given Çclass applÈ:growlAppName, Çclass anotÈ:allNotifications, Çclass dnotÈ:enabledNotifications, Çclass iappÈ:iconApplication
		Çevent notifygrÈ given Çclass nameÈ:alertName, Çclass titlÈ:alertTitle, Çclass applÈ:growlAppName, Çclass descÈ:alertText
	end tell
end notifyWithGrowl

on NotifyWithoutGrowl(alertText, alertTitle)
	display notification alertText with title alertTitle
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
		NotifyWithoutGrowl(alertText, alertTitle)
	end if
end notifyMain
(* end notification code *)


main(missing value)

on alfred_script(q)
	main(q)
end alfred_script

on handle_string(q)
	main(q)
end handle_string
