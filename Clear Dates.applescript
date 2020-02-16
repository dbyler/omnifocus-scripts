(*
	# DESCRIPTION #
	
	Clears the start and due dates of the selected items.
	
	
	# LICENSE #

	Copyright © 2010-2020 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)


	# CHANGE HISTORY #

	2020-02-14
	-	Update for OmniFocus 3; remove old Growl code; removes option to set new context

	2017-04-23
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
	-	Added ability to specify a new tag for cleared items (off by default; change this in the
		script settings below)
	-	No longer fails when a Grouping divider is selected
	-	Reorganized; incorporated Rob Trew's method to get items from OmniFocus
	-	Fixes potential issue when launching from OmniFocus toolbar
	-	Added to GitHub repo

	2010-11-03
	- Added option to change tag 
	
	2010-06-22
	- Re-fixed autosave
	
	2010-06-21
	- Encapsulated autosave in "try" statements in case this fails


	# INSTALLATION #

	1. Copy to ~/Library/Scripts/Applications/Omnifocus
 	2. If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

*)

-- To change settings, modify the following properties
property showNotification : true --if true, will display success notifications

on main()
	tell application "OmniFocus"
		tell content of first document window of front document
			--Get selection
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder and class of its value is not tag and class of its value is not perspective)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				display notification "No valid task(s) selected" with title "Error"
				return
			end if
			
			--Perform action
			set successTot to 0
			set autosave to false
			repeat with thisItem in validSelectedItemsList
				set succeeded to my clearDate(thisItem)
				if succeeded then set successTot to successTot + 1
			end repeat
			set autosave to true
		end tell
	end tell
	
	--Display summary notification
	if showNotification then
		if successTot > 1 then
			set alertItemNum to "s"
		else
			set alertItemNum to ""
		end if
		set alertText to successTot & " item" & alertItemNum & " processed" as string
		display notification alertText with title "Dates cleared"
	end if
end main

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

main()
