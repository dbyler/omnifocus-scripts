(*
	# DESCRIPTION #
	
	Creates a Completed task in the folder, project, and context of your choosing.
		
	# LICENSE #

	Copyright © 2015-2017 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)

	# CHANGE HISTORY #

  2018-03-15
  - Updated for compatibility with a breaking change in OmniFocus' AppleScript Dictionary

	2015-05-19
	-	Initial version

	# CONFIGURATION #

	1. set myFolderName to the name of the folder containing your the destination project
	2. set myProjectName to the name of the destination project
	3. set myContextName to the name of the destination context
	4. Save this script in a place that can be indexed by LaunchBar or Alfred

*)

property myFolderName : "Miscellaneous"
property myProjectName : "Ad Hoc"
property myContextName : "Not Working"


on log_item(myTask)
	tell application "OmniFocus"
		tell default document
			-- project
			set myFolder to (get first folder whose name is myFolderName)
			repeat with thisProject in (flattened projects in myFolder)
				if name of thisProject is equal to myProjectName then
					set myProject to thisProject
					exit repeat
				end if
			end repeat
			
			-- context
			set myContext to (get first context whose name is myContextName)
			
			tell myProject
				set myTask to make task with properties {name:myTaskName, context:myContext}
				mark complete myTask
			end tell
			
			display notification "\"" & myTask & "\"" & " logged to " & name of myProject
			
		end tell
	end tell
end log_item

on handle_string(mystring)
	my log_item(mystring)
end handle_string

on alfred_script(q)
	main(q)
end alfred_script

on run
	tell application "OmniFocus"
		activate
		set mystring to text returned of (display dialog "Log in" & myProjectName & ":" default answer "Completed task description")
		my log_item(mystring)
	end tell
end run