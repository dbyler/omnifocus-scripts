(*
	# DESCRIPTION #
	
	Clears the start and due dates of the selected items.
	
	
	# LICENSE #

	Copyright � 2010-2017 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)


	# CHANGE HISTORY #

	2017-04-23
	-	Fixes an issue when running with certain top-level category separators selected
	-	Minor update to notification code

	0.5.2 (2015-05-17)
	-	Use Notification Center instead of an alert when not running Growl. Requires Mountain Lion or newer

	0.5.1 (2011-10-31)
	-	Updated Growl code to work with Growl 1.3 (App Store version)
	-	Updated tell syntax to call "first document window", not "front document window"

	0.5 (2011-08-30)
	-	Rewrote notification code to gracefully handle situations where Growl is not installed

	0.4 (2011-07-07)
	-	Added ability to specify a new context for cleared items (off by default; change this in the
		script settings below)
	-	No longer fails when a Grouping divider is selected
	-	Reorganized; incorporated Rob Trew's method to get items from OmniFocus
	-	Fixes potential issue when launching from OmniFocus toolbar
	-	Added to GitHub repo

	0.3 "Someday Branch" 2010-11-03: Added option to change context 
	0.2.1 2010-06-22: Re-fixed autosave
	0.2 2010-06-21: Encapsulated autosave in "try" statements in case this fails
	0.1: Initial release.


	# INSTALLATION #

	1. Copy to ~/Library/Scripts/Applications/Omnifocus
 	2. If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus



	# KNOWN ISSUES #
	-	None
		
*)

-- To change settings, modify the following properties
property changeContext : false --true/false; if true, set newContextName (below)
property newContextName : "Someday" --context the item will change to if changeContext = true

property showSummaryNotification : false --if true, will display success notifications
property useGrowl : true --if true (and showAlert is true), uses Growl for alerts

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
		tell content of first document window of front document
			--Get selection
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
			set successTot to 0
			set autosave to false
			if changeContext then set newContext to my getContext(newContextName)
			repeat with thisItem in validSelectedItemsList
				if changeContext then set context of thisItem to newContext
				set succeeded to my clearDate(thisItem)
				if succeeded then set successTot to successTot + 1
			end repeat
			set autosave to true
		end tell
	end tell
	
	--Display summary notification
	if showSummaryNotification then
		set alertName to "General"
		set alertTitle to "Script complete"
		if successTot > 1 then set alertItemNum to "s"
		set alertText to "Date(s) cleared for " & successTot & " item" & alertItemNum & "." as string
		my notify(alertName, alertTitle, alertText)
	end if
end main

on getContext(contextName)
	tell application "OmniFocus"
		tell front document
			set contextID to id of item 1 of (complete contextName as context)
			return first context whose id is contextID
		end tell
	end tell
end getContext

on clearDate(selectedItem)
	set success to false
	tell application "OmniFocus"
		try
			set defer date of selectedItem to missing value
			set due date of selectedItem to missing value
			set success to true
		end try
	end tell
	return success
end clearDate

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
		�event register� given �class appl�:growlAppName, �class anot�:allNotifications, �class dnot�:enabledNotifications, �class iapp�:iconApplication
		�event notifygr� given �class name�:alertName, �class titl�:alertTitle, �class appl�:growlAppName, �class desc�:alertText
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

main()
