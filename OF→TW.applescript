(*
	Email Selected Tasks to Teamwork
	
	# DESCRIPTION #
	
	This script generates an email from selected OmniFocus tasks to send to Teamwork
	-	If multiple tasks are selected:
		-	Those that share a context are grouped together
		-	A unique email will be created for each selected context
	-	For each context (person), the first project becomes the email destination
	-	The project title will be used in the email recipient (spaces are removed)
	-	Due date, if available, is added to the email subject in [mm-dd-yyyy] format	
	
	# LICENSE #
	
	Copyright 2014-2015 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)
	
	
	# CHANGE HISTORY #
	
	2.3 (2015-06-30)
		- Context is hidden from subject if not set in OmniFocus
		- Due date is included in subject, if available
		- Fix for issue when "&" appears in the task title or body
		- Uses Postbox's AppleScript dictionary when using Postbox
		- Added "!!!" priority designator to subject
		
	
	2.2 (2014-12-08)
		- Fixed @@ bug
		- Brings mail application to front after running
		- Changed behavior of "grouped" tasks. Now an email will contain multiple tasks only if they share a project AND context.
	2.1 (2014-11-04)
		- Fixes issue when running from OmniFocus toolbar
		- Works with Inbox items (prompts for project if there is none)
		- Option to use system default mail application, not just Mail.app
		
	2.0 (2014-10-31) New version
	0.1 (2011-09-23) Original release (based on Snooze script)

	
	# INSTALLATION #

	- 	Copy this script to OmniFocus scripts folder
		- To find this, in OmniFocus, go to Help -> Open Scripts Folder
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar...

	# KNOWN ISSUES #
	-	None
		
*)

-- To change settings, modify the following properties
property fromAddress : "mitra <angelkyodo@transformativechange.org>"
property useMail : false --set to "true" to use Apple Mail. Set to "false" otherwise
property usePostbox : true --set to "true" to use Postbox. Set to "false" otherwise (will use the system default email client if both are false)

on main()
	set email_list to {}
	
	tell application "OmniFocus"
		tell content of front document window of front document
			--Get selection
			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder)
			set totalItems to count of validSelectedItemsList
			if totalItems is 0 then
				my notifyWithoutGrowl("No valid task(s) selected")
				return
			end if
			
			repeat with thisItem in validSelectedItemsList
				set theTitle to name of thisItem
				set theNote to (note of contents of thisItem)
				try
					set theParentName to (my replace_chars(" ", "", (name of containing project of thisItem)))
				on error
					display dialog theTitle & " has no containing project. Please enter a project name:" default answer "akw"
					set theParentName to text returned of result
				end try
				try
					set theContext to ("@" & name of context of thisItem)
				on error
					set theContext to ""
				end try
				
				try
					set theDate to due date of thisItem
					set theDueDateString to (my pyFormatTime(theDate))
				on error
					set theDueDateString to ""
				end try
				
				set newRecord to {eContext:theContext, eNote:theNote, eBody:theTitle, eDue:theDueDateString, eProject:theParentName}
				
				if length of email_list is 0 then
					set end of email_list to newRecord
				else
					set added to false
					repeat with email in email_list
						if eContext of newRecord is eContext of email and eProject of newRecord is eProject of email then
							set eBody of email to (eBody of email) & "
" & eBody of newRecord
							set added to true
						end if
						if not added then
							set end of email_list to newRecord
						end if
					end repeat
				end if
			end repeat
			
			repeat with email in email_list
				set theSubject to eBody of email & " " & eContext of email & " " & eDue of email & " !!!"
				set theRecipient to eProject of email & "@tasks.teamwork.com"
				set theBody to eBody of email & "


#End"
				my sendMessage(theRecipient, theSubject, theBody)
			end repeat
		end tell
	end tell
end main

on sendMessage(emailRecipient, emailSubject, emailBody)
	if useMail then
		tell application "Mail"
			activate
			set theOutMessage to make new outgoing message with properties {visible:true}
			tell theOutMessage
				make new to recipient at end of to recipients with properties {address:emailRecipient}
				set sender to fromAddress
				set subject to emailSubject
				set content to emailBody
			end tell
		end tell
	else if usePostbox then
		tell application "Postbox"
			activate
			send message subject emailSubject body emailBody recipient emailRecipient
		end tell
	else
		set emailSubject to (my replace_chars("&", "–", emailSubject))
		set emailBody to (my replace_chars("&", "–", emailBody))
		tell application "System Events" to open location "mailto:" & emailRecipient & "?subject=" & emailSubject & "&body=" & emailBody
	end if
end sendMessage

on pyFormatTime(AS_Date)
	set timeFormat to quoted form of "[%m/%d/%Y]"
	return (do shell script "/usr/bin/python -c \"import time, dateutil.parser; print dateutil.parser.parse('" & AS_Date & "').strftime(" & timeFormat & "); \"")
end pyFormatTime

on replace_chars(search_string, replacement_string, this_text)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars

on notifyWithoutGrowl(alertText)
	tell application "OmniFocus" to display dialog alertText with icon 1 buttons {"OK"} default button "OK"
end notifyWithoutGrowl

main()
