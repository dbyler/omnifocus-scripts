(*
	# DESCRIPTION #

	Displays the total estimated time of currently selected actions or projects.
	

	# LICENSE #
	
	Copyright © 2011-2017 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php) 
	(TL;DR: do whatever you want with it.)


	# CHANGE HISTORY #

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
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"

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

on notifyWithGrowl(growlHelperAppName, alertName, alertTitle, alertText, useSticky)
	tell my application growlHelperAppName
		Çevent registerÈ given Çclass applÈ:growlAppName, Çclass anotÈ:allNotifications, Çclass dnotÈ:enabledNotifications, Çclass iappÈ:iconApplication
		Çevent notifygrÈ given Çclass nameÈ:alertName, Çclass titlÈ:alertTitle, Çclass applÈ:growlAppName, Çclass descÈ:alertText
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
