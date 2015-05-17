(*
	# DESCRIPTION # 
	
	Appends a note to the selected OmniFocus task(s).
	-	By default, the clipboard contents are used for the note
	-	If triggered from LaunchBar or Alfred, you can use different text	

	See https://github.com/dbyler/omnifocus-scripts for updates


	# LICENSE #

	Copyright © 2015 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)


	# CHANGE HISTORY #


	1.0.1 (2015-05-17)
	-	Fix for attachments being overwritten by the note
	-	Use Notification Center instead of an alert when not running Growl. Requires Mountain Lion or newer
	
	1.0 (2015-05-09) Original release.
	
*)-- To change settings, modify the following propertiesproperty showSummaryNotification : true --if true, will display success notifications-- Don't change theseproperty growlAppName : "Dan's Scripts"property allNotifications : {"General", "Error"}property enabledNotifications : {"General", "Error"}property iconApplication : "OmniFocus.app"on main(q)	if q is missing value then		set q to (the clipboard)	end if		tell application "OmniFocus"		tell content of first document window of front document			--Get selection			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder)			set totalItems to count of validSelectedItemsList			if totalItems is 0 then				set alertName to "Error"				set alertTitle to "Error"				set alertText to "No valid task(s) selected"				my notify(alertName, alertTitle, alertText)				return			end if						if totalItems > 1 then				display dialog "Multiple items selected. Continue?" buttons {"Cancel", "OK"} default button 2			end if						repeat with thisItem in validSelectedItemsList				tell thisItem					insert q & "

" at before first paragraph of note				end tell			end repeat						if showSummaryNotification then				set alertName to "General"				set alertTitle to "\"" & q & "\""				if length of alertTitle > 20 then					set alertTitle to (text 1 thru 20 of alertTitle) & "…\""				end if				if totalItems > 1 then					set alertText to "Note appended to " & totalItems & " selected tasks"				else					set alertText to "Note appended to: 
" & name of first item in validSelectedItemsList				end if				my notify(alertName, alertTitle, alertText)			end if					end tell	end tellend main(* Begin notification code *)on notify(alertName, alertTitle, alertText)	--Call this to show a normal notification	my notifyMain(alertName, alertTitle, alertText, false)end notifyon notifyWithSticky(alertName, alertTitle, alertText)	--Show a sticky Growl notification	my notifyMain(alertName, alertTitle, alertText, true)end notifyWithStickyon IsGrowlRunning()	tell application "System Events" to set GrowlRunning to (count of (every process where creator type is "GRRR")) > 0	return GrowlRunningend IsGrowlRunningon notifyWithGrowl(growlHelperAppName, alertName, alertTitle, alertText, useSticky)	tell my application growlHelperAppName		«event register» given «class appl»:growlAppName, «class anot»:allNotifications, «class dnot»:enabledNotifications, «class iapp»:iconApplication		«event notifygr» given «class name»:alertName, «class titl»:alertTitle, «class appl»:growlAppName, «class desc»:alertText	end tellend notifyWithGrowlon NotifyWithoutGrowl(alertText)	display notification alertTextend NotifyWithoutGrowlon notifyMain(alertName, alertTitle, alertText, useSticky)	set GrowlRunning to my IsGrowlRunning() --check if Growl is running...	if not GrowlRunning then --if Growl isn't running...		set GrowlPath to "" --check to see if Growl is installed...		try			tell application "Finder" to tell (application file id "GRRR") to set strGrowlPath to POSIX path of (its container as alias) & name		end try		if GrowlPath is not "" then --...try to launch if so...			do shell script "open " & strGrowlPath & " > /dev/null 2>&1 &"			delay 0.5			set GrowlRunning to my IsGrowlRunning()		end if	end if	if GrowlRunning then		tell application "Finder" to tell (application file id "GRRR") to set growlHelperAppName to name		notifyWithGrowl(growlHelperAppName, alertName, alertTitle, alertText, useSticky)	else		NotifyWithoutGrowl(alertText)	end ifend notifyMain(* end notification code *)main(missing value)on alfred_script(q)	main(q)end alfred_scripton handle_string(q)	main(q)end handle_string