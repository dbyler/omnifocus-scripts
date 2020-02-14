(*
	# DESCRIPTION #

	Displays the total estimated time of currently selected actions or projects.
	

	# LICENSE #
	
	Copyright © 2011-2017 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php) 
	(TL;DR: do whatever you want with it.)


	# CHANGE HISTORY #

	2020-02-14
	-	Remove Growl code; better notification text

	2018-11-01
	-	Fix for OmniFocus 3 ("Contexts" replaced with "Tags")

	2017-04-23
	-	Fixes an issue when running with certain top-level category separators selected
	-	Minor update to notification code

	2011-10-31
	-	Updated Growl code to work with Growl 1.3 (App Store version)
	-	Updated tell syntax to call "first document window", not "front document window"

	2011-08-30
	-	Rewrote notification code to gracefully handle situations where Growl is not installed
	
	2011-07-18
	-	Fixed bug where time might not be displayed accurately
		(Thanks to Ricardo Matias for the bug report)

	2011-07-07
	-	Streamlined calls to OmniFocus with Rob Trew's input (Thanks, Rob!)
	-	Reorganized script for better readability
	
	0.1: Initial release


	# INSTALLATION #

	-	Copy to ~/Library/Scripts/Applications/Omnifocus
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus


	# KNOWN BUGS #
	-	None
		
*)

-- To change settings, modify the following property
property useGrowl : false --if true, will use Growl for success/failure alerts

-- Don't change these
property growlAppName : "Dan's Scripts"

on main()
	tell application "OmniFocus"
		tell content of first document window of front document
			--Get selection
			set totalMinutes to 0
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder and class of its value is not tag and class of its value is not perspective)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				display notification alertText with title alertTitle
				return
			end if
			
			--Perform action
			repeat with thisItem in validSelectedItemsList
				set thisEstimate to estimated minutes of thisItem
				if thisEstimate is not missing value then set totalMinutes to totalMinutes + thisEstimate
			end repeat
			set modMinutes to (totalMinutes mod 60)
			set totalHours to (totalMinutes div 60)
		end tell
	end tell
	
	--Show summary notification
	if totalItems is 1 then
		set itemSuffix to ""
	else
		set itemSuffix to "s"
	end if
	set alertName to "General"
	set alertTitle to (totalHours & "h " & modMinutes & "m total") as string
	set alertText to ("Estimate for " & totalItems & " item" & itemSuffix) as string
	display notification alertText with title alertTitle
end main


main()
