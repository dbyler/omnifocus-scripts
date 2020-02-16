(*
	# DESCRIPTION #
	
	This script takes the currently selected actions or projects and sets them for action this weekend.
	(If a weekend is currently in progress, the items will be set for the *current* weekend.)
	
	**IMPORTANT: The script will now always set a start date. Whether it sets a due date is up to you.
	Change this setting with the setDueDate property below.**
	
	The dates and times are set by variables, so you can modify to meet your weekend.
	
	# LICENSE #

	Copyright © 2010-2020 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	

	# CHANGE HISTORY #

	2020-02-14
	-	Updated for OmniFocus 3; removes Growl support; other small improvements

	2017-04-23
	-	Fixes an issue when running with certain top-level category separators selected
	-	Minor update to notification code. Next time I'll probably remove Growl altogether

	2015-05-17
	-	Use Notification Center instead of an alert when not running Growl. Requires Mountain Lion or newer
	
	2011-10-31
	-	Updated Growl code to work with Growl 1.3 (App Store version)
	-	Updated tell syntax to call "first document window", not "front document window"
	
	2011-08-30
	-	Rewrote notification code to gracefully handle situations where Growl is not installed
	
	2011-07-07
	-	Setting a due date is now optional (see settings below)
	-	No longer fails when a Grouping divider is selected
	-	Reorganized; incorporated Rob Trew's method to get items from OmniFocus
	-	Fixes potential issue when launching from OmniFocus toolbar

	2010-06-22
		-	Actual fix for autosave

	2010-06-21
		-	Encapsulated autosave in "try" statements in case this fails

	2010: Initial release. Based on my Defer script, which incorporates bug fixes from Curt Clifton. By default, notifications are disabled (uncomment the appropriate lines to enable them).


	# INSTALLATION #

	1. Copy to ~/Library/Scripts/Applications/Omnifocus
 	2. If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

	# KNOWN BUGS #
	
	- When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus returns an error. This issue does not occur when invoked from the script menu, a Quicksilver trigger, etc.
		
*)

-- To change your weekend start/stop date/time, modify the following properties
property setDueDate : false --if False, will not modify the due date; if True, sets due date
property deferDay : Friday
property deferHour : 18 --due time in hrs (24 hr clock)
property dueDay : Sunday
property dueHour : 16 --due time in hours (24 hr clock)

--To enable alerts, change these settings to True _and_ uncomment
property showSummaryNotification : true --if true, will display success notifications

-- Don't change these
property alertItemNum : ""
property alertDayNum : ""
property dueDate : ""

on main()
	tell application "OmniFocus"
		tell content of first document window of front document
			--Get selection
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder and class of its value is not tag and class of its value is not perspective)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				display notification alertText with title alertTitle
				return
			end if
			
			--Calculate due date
			set dueDate to current date
			set theTime to time of dueDate
			repeat while weekday of dueDate is not dueDay
				set dueDate to dueDate + 1 * days
			end repeat
			set dueDate to dueDate - theTime + dueHour * hours
			--set dueDate to dueDate + 1 * weeks --uncomment to use _next_ weekend instead
			
			--Calculate start date
			set diff to dueDay - deferDay
			if diff < 0 then set diff to diff + 7
			set diff to diff * days + (dueHour - deferHour) * hours
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
		set alertText to successTot & " item" & alertItemNum & " set to this weekend." as string
		display notification alertText with title "Script complete"
	end if
end main

on setDate(selectedItem, startDate, dueDate)
	set success to false
	tell application "OmniFocus"
		try
			set defer date of selectedItem to startDate
			if setDueDate then set due date of selectedItem to dueDate
			set success to true
		end try
	end tell
	return success
end setDate


main()