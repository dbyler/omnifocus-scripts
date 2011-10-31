(*
	# DESCRIPTION #

	This script sums the estimated times of currently selected actions or projects.
	

	# LICENSE #
	
	Copyright © 2011 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php) 
	(TL;DR: do whatever you want with it.)


	# CHANGE HISTORY #

	0.31 (2011-10-31)
	-	Updated Growl code to work with Growl 1.3 (App Store version)
	-	Updated tell syntax to call "first document window", not "front document window"

	0.3 (2011-08-30)
	-	Rewrote notification code to gracefully handle situations where Growl is not installed
	
	0.2b (2011-07-18)
	-	Fixed bug where time might not be displayed accurately
		(Thanks to Ricardo Matias for the bug report)

	0.2 (2011-07-07):
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
property useGrowl : true --if true, will use Growl for success/failure alerts

-- Don't change these
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"

on main()
	tell application "OmniFocus"
		tell content of first document window of front document
			--Get selection
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
	set alertTitle to "Script complete"
	set alertText to totalHours & "h " & modMinutes & "m total for " & totalItems & " item" & itemSuffix as string
	my notify(alertName, alertTitle, alertText)
end main

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
	if GrowlRunning then
		tell application "Finder" to tell (application file id "GRRR") to set growlHelperAppName to name
		notifyWithGrowl(growlHelperAppName, alertName, alertTitle, alertText, useSticky)
	else
		NotifyWithoutGrowl(alertText)
	end if
end notifyMain
(* end notification code *)

main()
