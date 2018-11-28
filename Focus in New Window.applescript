(*
	# DESCRIPTION #
	
	Opens the selected task's project in a new window so you can jump from a context
	perspective view into the project without losing place.
	
	(Also works with multiple items selected)
	
	# LICENSE #
	
	Copyright © 2015-2017 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)
	
	# CHANGE HISTORY #
	
	2018-11-28
	-	Updated to work with OmniFocus 3

	2017-04-23
	-	Fixes an issue when running with certain top-level category separators selected

	2015-04-28
	-	Initial release
		
*)


on main()
	tell application "OmniFocus"
		set myFocus to {}
		-- get selection
		tell content of front document window of front document
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder and class of its value is not tag and class of its value is not perspective)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				my notifyWithoutGrowl("No valid task(s) selected")
				return
			end if
			repeat with validSelectedItem in validSelectedItemsList
				validSelectedItem
				if (containing project of validSelectedItem) is not missing value then
					set end of myFocus to (containing project of validSelectedItem)
				else if (assigned container of validSelectedItem) is not missing value then
					set end of myFocus to (assigned container of validSelectedItem)
				end if
			end repeat
		end tell
		
		-- no valid projects to focus on
		if length of myFocus is 0 then
			my notifyWithoutGrowl("No projects to focus")
			return
		end if
		
		-- make new window
		tell default document
			make new document window with properties {perspective name:"Projects"}
		end tell
		
		-- set focus
		tell front document window of front document
			set focus to myFocus
		end tell
	end tell
end main

on notifyWithoutGrowl(alertText)
	try
		display notification alertText with title "OmniFocus Script Complete"
	end try
end notifyWithoutGrowl

main()
