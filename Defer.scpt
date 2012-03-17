(*
	# DESCRIPTION #
	
	This script takes the currently selected actions or projects and offsets their dates by the
	user-specified number of days. The user may defer just the due date or both the start and
	due dates (useful for skipping weekends for daily recurring tasks).
	
	
	# LICENSE #

	Copyright © 2008-2011 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)

	
	# CHANGE HISTORY#
	
	0.7 (2011-10-31)
	-	Now has "Start Only" mode that only modifies start dates. To use, set promptForChangeScope to false
		and changeScope to "Start Only"
	-	Updated Growl code to work with Growl 1.3 (App Store version)
	-	Updated tell syntax to call "first document window", not "front document window"
	
	0.6 (2011-08-30)
	-	Rewrote notification code to gracefully handle situations where Growl is not installed
	-	Changed default promptForChangeScope to False
	
	0.5 (2011-07-14)
	-	Now warns for mismatches between "actual" and "effective" Start and Due dates. Such mismatches 
		occur if a parent or ancestor item has an earlier Due date (or later Start date) than the selected item.
		This warning can be suppressed by setting "warnOnDateMismatch" property to "false".

	-	New "promptForChangeScope" setting lets users bypass the second dialog box if they always change
		the same parameters (Start AND Due dates, or just Due dates). Default setting: enabled.
	
	0.4 (2011-07-07)
	-	New option to set start time (Default: 8am)
	-	New snoozeUnscheduledItems option (default: True) lets you push the start date of unscheduled items.
	-	No longer fails when a Grouping divider is selected
	-	Reorganized; incorporated Rob Trew's method to get items from OmniFocus
	-	Fixes potential issue when launching from OmniFocus toolbar
	
	0.3c (2010-06-21)
		-	Actual fix for autosave
	
	0.3b (2010-06-21)
		-	Encapsulated autosave in "try" statements in case this fails
	
	0.3 (2010-06-15)
		-	Incorporated another improvement from Curt Clifton to increase performance
		-	Reinstated original Growl code since the Growl-agnostic code broke in Snow Leopard
	
	0.2
		-	Incorporated Curt Clifton's bug fixes to make script more reliable when dealing with multiple items.
			Thanks, Curt!
		-	Added some error suppression to deal with deferring from Context mode
		-	Defers both start and due dates by default.
		-	Incorporates new method that doesn't call Growl directly. This code should be friendly for machines
			that don't have Growl installed. In my testing, I found that GrowlHelperApp crashes on nearly 10%
			of AppleScript calls, so the script checks for GrowlHelperApp and launches it if not running. (Thanks 
			to Nanovivid from forums.cocoaforge.com/viewtopic.php?p=32584 and Macfaninpdx from 
			forums.macrumors.com/showthread.php?t=423718 for the information needed to get this working
		-	All that said... if you run from the toolbar frequently, I'd recommend  turning alerts off since Growl 
			slows down the script so much
		
	0.1: Original release


	# INSTALLATION #

	-	Copy to ~/Library/Scripts/Applications/Omnifocus
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus


	# KNOWN ISSUES #
	-	When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus displays an alert.
		This does not occur when invoked from another launcher (script menu, FastScripts LaunchBar, etc).

*)

-- To change settings, modify the following properties
property snoozeUnscheduledItems : true --if True, when deferring Start AND Due dates, will set start date to given # of days in the future
property showSummaryNotification : true --if true, will display success notifications
property useGrowl : true --if true, will use Growl for success/failure alerts
property defaultOffset : 1 --number of days to defer by default
property defaultStartTime : 8 --default time to use (in hours, 24-hr clock)
property warnOnDateMismatch : true --if True, warns you if there's a mismatch between a deferred item's actual and effective Due date. An effective due date is set by a parent task or project.

--If you always want to change the same type of information--(Start AND Due dates) OR (Just Due dates)--change promptForChangeScope to false
property promptForChangeScope : false
property changeScope : "Start and Due" --options: "Start and Due", "Due Only", "Start Only"

-- Don't change these
property alertItemNum : ""
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
			display dialog "Defer for how many days (from existing)?" default answer defaultOffset buttons {"Cancel", "OK"} default button 2
			set daysOffset to (the text returned of the result) as integer
			if promptForChangeScope then
				set changeScopeQuery to display dialog "Modify start and due dates?" buttons {"Cancel", "Due Only", "Start and Due"} ¬
					default button 3 with icon caution giving up after 60
				set changeScope to button returned of changeScopeQuery
				if changeScope is "Cancel" then return
			end if
			if changeScope is "Start and Due" then
				set modifyStartDate to true
				set modifyDueDate to true
			else if changeScope is "Due Only" then
				set modifyStartDate to false
				set modifyDueDate to true
			else if changeScope is "Start Only" then
				set modifyStartDate to true
				set modifyDueDate to false
			end if
			
			--Perform action
			set successTot to 0
			set autosave to false
			set todayStart to (current date) - (get time of (current date)) + (defaultStartTime * 3600)
			repeat with thisItem in validSelectedItemsList
				set succeeded to my defer(thisItem, daysOffset, modifyStartDate, modifyDueDate, todayStart)
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
		set alertText to successTot & " item" & alertItemNum & " deferred " & daysOffset & " day" & alertDayNum & ". (" & changeScope & ")" as string
		my notify(alertName, alertTitle, alertText)
	end if
end main

on defer(selectedItem, daysOffset, modifyStartDate, modifyDueDate, todayStart)
	set success to false
	tell application "OmniFocus"
		try
			set realStartDate to start date of selectedItem
			set {startAncestor, effectiveStartDate} to my getEffectiveStartDate(selectedItem, start date of selectedItem)
			set realDueDate to due date of selectedItem
			set {dueAncestor, effectiveDueDate} to my getEffectiveDueDate(selectedItem, due date of selectedItem)
			if modifyStartDate then
				if (realStartDate is not missing value) then --There's a preexisting start date
					set start date of selectedItem to my offsetDateByDays(realStartDate, daysOffset)
					if warnOnDateMismatch then
						if realStartDate is not effectiveStartDate then
							set alertText to "«" & (name of contents of selectedItem) & ¬
								"» has a later effective start date inherited from «" & (name of contents of dueAncestor) & ¬
								"». The latter has not been changed."
							my notifyWithSticky("Error", "Possible Start Date Mismatch", alertText)
						end if
					end if
				end if
			end if
			if (realDueDate is not missing value) then --There's a preexisting due date
				if modifyDueDate then
					set due date of selectedItem to my offsetDateByDays(realDueDate, daysOffset)
				end if
				if realDueDate is not effectiveDueDate then --alert if there's a different effective date
					--				contents of selectedItem
					if modifyDueDate and warnOnDateMismatch then
						set alertText to "«" & (name of contents of selectedItem) & ¬
							"» has an earlier effective due date inherited from «" & (name of contents of dueAncestor) & ¬
							"». The latter has not been changed."
						my notifyWithSticky("Error", "Possible Due Date Mismatch", alertText)
					end if
				end if
			else if snoozeUnscheduledItems then
				if start date of selectedItem is missing value then
					set test to my offsetDateByDays(todayStart, daysOffset)
					set start date of selectedItem to my offsetDateByDays(todayStart, daysOffset)
				end if
			end if
			set success to true
		end try
	end tell
	return success
end defer

on getEffectiveDueDate(thisItem, effectiveDueDate)
	tell application "OmniFocus"
		if due date of thisItem is not missing value then
			if effectiveDueDate is missing value then
				set effectiveDueDate to due date of thisItem
			else if due date of thisItem is less than effectiveDueDate then
				set effectiveDueDate to due date of thisItem
			end if
		end if
		if parent task of thisItem is missing value then
			return {thisItem, effectiveDueDate}
		else
			return my getEffectiveDueDate(parent task of thisItem, effectiveDueDate)
		end if
	end tell
	return {dueAncestor, effectiveDueDate}
end getEffectiveDueDate

on getEffectiveStartDate(thisItem, effectiveStartDate)
	tell application "OmniFocus"
		if start date of thisItem is not missing value then
			if effectiveStartDate is missing value then
				set effectiveStartDate to start date of thisItem
			else if start date of thisItem is greater than effectiveStartDate then
				set effectiveStartDate to start date of thisItem
			end if
		end if
		if parent task of thisItem is missing value then
			return {thisItem, effectiveStartDate}
		else
			return my getEffectiveStartDate(parent task of thisItem, effectiveStartDate)
		end if
	end tell
	return {startAncestor, effectiveStartDate}
end getEffectiveStartDate

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
	if useGrowl and GrowlRunning then
		tell application "Finder" to tell (application file id "GRRR") to set growlHelperAppName to name
		notifyWithGrowl(growlHelperAppName, alertName, alertTitle, alertText, useSticky)
	else
		NotifyWithoutGrowl(alertText)
	end if
end notifyMain
(* end notification code *)

main()
