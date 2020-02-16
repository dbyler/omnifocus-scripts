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
	
	Copyright © 2011-2020 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php) 
	(TL;DR: do whatever you want with it.)
	

	# CHANGE HISTORY #

	2020-02-14
	-	Updated for OmniFocus 3; removes Growl support; other small improvements

	2017-04-22
	-	Fixes an issue when running with certain top-level category separators selected
	-	Minor update to notification code

	2015-05-17
	-	Use Notification Center instead of an alert when not running Growl. Requires Mountain Lion or newer

	2011-10-31
	-	Updated Growl code to work with Growl 1.3 (App Store version)
	-	Updated tell syntax to call "first document window", not "front document window"

	2011-08-30
	-	Rewrote notification code to gracefully handle situations where Growl is not installed
	
	2011-07-07
	-	New setting: "Start" or "Due" modes (see above)
	-	No longer fails when a Grouping divider is selected
	-	Streamlined calls to OmniFocus with Rob Trew's input (Thanks, Rob!)
	-	Reorganized script for better readability

	2010-06-22
	-	Actual fix for autosave

	2010-06-21
	-	Encapsulated autosave in "try" statements in case this fails

	2010-06-15
	-	Added performance optimization (thanks to Curt Clifton)
	-	Fixed Growl code (broke with Snow Leopard)
	-	Switched to MIT license (simpler, less restrictive)

	2010: Initial release. Based on my Defer script, which incorporates bug fixes from Curt Clifton. Also uses method that doesn't call Growl directly. This code should be friendly for machines that don't have Growl installed. In my testing, I found that GrowlHelperApp crashes on nearly 10% of AppleScript calls, so the script checks for GrowlHelperApp and launches it if not running. (Thanks to Nanovivid from forums.cocoaforge.com/viewtopic.php?p=32584 and Macfaninpdx from forums.macrumors.com/showthread.php?t=423718 for the information needed to get this working

	# INSTALLATION #

	-	Copy to ~/Library/Scripts/Applications/Omnifocus
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

	# KNOWN BUGS #
	- When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus returns an error. This issue does not occur when invoked from the script menu, a Quicksilver trigger, etc.
		
*)

--The following setting changes script mode. Options: "start" or "due" (quotes needed)
property mode : "start"

property showSummaryNotification : true --if true, will display success notifications
property deferHour : 6 --Start hour for items not previously assigned a start time (24 hr clock)display notification alertText with title alertTitle
property dueHour : 17 --Due hour for items not previously assigned a due time (24 hr clock)

-- Don't change these
property alertItemNum : ""
property alertDayNum : ""

on main()
	tell application "OmniFocus"
		tell content of first document window of front document
			--Get selection
			set totalMinutes to 0
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder and class of its value is not tag and class of its value is not perspective)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				display notification alertText with title alertTitle
				return
			end if
			
			--Perform action
			set successTot to 0
			set autosave to false
			set newDate to (current date) - (time of (current date))
			if mode is "start" then
				repeat with thisItem in validSelectedItemsList
					set succeeded to my setStartDate(thisItem, newDate)
					if succeeded then set successTot to successTot + 1
				end repeat
			else if mode is "due" then
				repeat with thisItem in validSelectedItemsList
					set succeeded to my setDueDate(thisItem, newDate)
					if succeeded then set successTot to successTot + 1
				end repeat
			else
				set alertTitle to "Script failure"
				set alertText to "Improper mode setting"
				display notification alertText with title alertTitle
			end if
			set autosave to true
		end tell
	end tell
	
	--Display summary notification
	if showSummaryNotification then
		set alertTitle to "Script complete"
		if successTot > 1 then set alertItemNum to "s"
		set alertText to successTot & " item" & alertItemNum & " set to today." as string
		display notification alertText with title alertTitle
	end if
end main

on setStartDate(selectedItem, newDate)
	set success to false
	tell application "OmniFocus"
		try
			set originalStartDateTime to defer date of selectedItem
			if (originalStartDateTime is not missing value) then
				--Set new start date with original start time
				set defer date of selectedItem to (newDate + (time of originalStartDateTime))
				set success to true
			else
				set defer date of selectedItem to (newDate + (deferHour * hours))
				set success to true
			end if
		end try
	end tell
	return success
end setStartDate

on setDueDate(selectedItem, newDate)
	set success to false
	tell application "OmniFocus"
		try
			set originalDueDateTime to due date of selectedItem
			if (originalDueDateTime is not missing value) then
				--Set new due date with original due time
				set originalDueStartDate to originalDueDateTime - (time of originalDueDateTime)
				set theDelta to (newDate - originalDueStartDate) / 86400
				set newDueDateTime to (originalDueDateTime + (theDelta * days))
				set due date of selectedItem to newDueDateTime
				set originalStartDateTime to defer date of selectedItem
				if (originalStartDateTime is not missing value) then
					set newStartDateTime to (originalStartDateTime + (theDelta * days))
					set defer date of selectedItem to newStartDateTime
				end if
				set success to true
			else
				set due date of selectedItem to (newDate + (dueHour * hours))
				set success to true
			end if
		end try
	end tell
	return success
end setDueDate

main()