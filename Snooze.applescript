(*
	# DESCRIPTION #
	
	Sets the start date of selected items to the specified # of days in the future *from now*.
	Snoozes from current time if a fraction/decimal is given.
	
	
	# LICENSE #
	
	Copyright © 2010-2020 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)
	
	
	# CHANGE HISTORY #
	
	2020-02-14
	-	Updated for OmniFocus 3; removes Growl support; other small improvements

	2017-04-23
	-	Fixes an issue when running with certain top-level category separators selected
	-	Minor update to notification code

	2015-05-17
	-	Use Notification Center instead of an alert when not running Growl. Requires Mountain Lion or newer
	
	2015-05-07
	-	Support passing # of days through LaunchBar and Alfred (unsupported)
	-	Support snoozing for a fraction of a day. You can use decimals (.01 days is about 15 minutes)
		or fractions (1/24 = 1 hour)	
	-	Shout out to Bill Palmer for an elegant way to snooze without counting seconds in a day
	
	2011-10-31
	-	Updated Growl code to work with Growl 1.3 (App Store version)
	-	Updated tell syntax to call "first document window", not "front document window"
	
	2011-08-30
	-	Rewrote notification code to gracefully handle situations where Growl is not installed
	-	Changed "The item/The items" to "It/They"
	
	2011-07-07
	-	New option to set start time (default: 8am)
	-	Reorganized; incorporated Rob Trew's method to get items from OmniFocus
	-	No longer fails when a Grouping divider is selected
	-	Fixes potential issue when launching from OmniFocus toolbar
	
	2010-06-22
	-	Actual fix for autosave
	
	2010-06-21
	-	Encapsulated autosave in "try" statements in case this fails
	
	2010-06-15
	-	Fixed Growl code
	-	Added performance optimization (thanks, Curt Clifton)
	-	Changed from LGPL to MIT license (MIT is less restrictive)
		
	2010: Original release. (Thanks to Curt Clifton, Nanovivid, and Macfaninpdx for various pieces of code)

	
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

on main(q)
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
					set alertTitle to "Error"
					set alertText to "Error interpreting your input. Please try an integer or fraction"
					display notification alertText with title alertTitle
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
		display notification "No items snoozed" with title "Error"
		return
	end if
	
	--Summary notification
	if showSummaryNotification then
		if daysOffset is not 1 then set alertDayNum to "s"
		if successTot > 1 then
			set alertItemPronoun to "They"
			set alertItemNum to "s"
		else
			set alertItemPronoun to "It"
			set alertItemNum to ""
		end if
		set alertTitle to (successTot & " item" & alertItemNum & " snoozed") as string
		set alertText to (alertItemPronoun & " will become available in " & daysOffset & " day" & alertDayNum) as string
		display notification alertText with title alertTitle
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


main(missing value)

on alfred_script(q)
	main(q)
end alfred_script

on handle_string(q)
	main(q)
end handle_string
