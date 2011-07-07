(*
	# DESCRIPTION #

	This script sums the estimated times of currently selected actions or projects.
	

	# LICENSE #
	
	Copyright © 2011 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php) 
	(TL;DR: do whatever you want with it.)


	# CHANGE HISTORY #

	version 0.2: Streamlined calls to OmniFocus with Rob Trew's input (Thanks, Rob!)
				Reorganized script for better readability
	version 0.1: Initial release


	# INSTALLATION #

	-	Copy to ~/Library/Scripts/Applications/Omnifocus
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus


	# KNOWN BUGS #
	-	None
		
*)

property showAlert : true --if true, will display success/failure alerts
property useGrowl : true --if true, will use Growl for success/failure alerts
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"

on main()
	tell application "OmniFocus"
		tell content of front document window of front document
			set totalMinutes to 0
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder)
			set totalItems to count of validSelectedItemsList
			
			if totalItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				my notify(alertName, alertTitle, alertText)
				return
			end if
			
			repeat with thisItem in validSelectedItemsList
				set thisEstimate to estimated minutes of thisItem
				if thisEstimate is not missing value then set totalMinutes to totalMinutes + thisEstimate
			end repeat
		end tell
	end tell
	
	if totalItems is 1 then
		set itemSuffix to ""
	else
		set itemSuffix to "s"
	end if
	
	set alertName to "General"
	set alertTitle to "Script complete"
	
	set modMinutes to (totalMinutes mod 60)
	set totalHours to (totalMinutes / 60 as integer)
	
	set alertText to totalHours & "h " & modMinutes & "m total for " & totalItems & " item" & itemSuffix as string
	
	my notify(alertName, alertTitle, alertText)
end main

on notify(alertName, alertTitle, alertText)
	if showAlert is false then
		return
	else if useGrowl is true then
		--check to make sure Growl is running
		tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		if GrowlRunning = 0 then
			--try to activate Growl
			try
				do shell script "/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
				do shell script "~/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
			end try
			delay 0.2
			tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		end if
		--notify
		if GrowlRunning ≥ 1 then
			try
				tell application "GrowlHelperApp"
					register as application growlAppName all notifications allNotifications default notifications allNotifications icon of application iconApplication
					notify with name alertName title alertTitle application name growlAppName description alertText
				end tell
			end try
		else
			set alertText to alertText & " 
 
p.s. Don't worry—the Growl notification failed but the script was successful."
			display dialog alertText with icon 1
		end if
	else
		display dialog alertText with icon 1
	end if
end notify

main()
