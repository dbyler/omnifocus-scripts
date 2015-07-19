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
	
	*)

-- To change settings, modify the following properties:

property mailClient : "Postbox" --options: Mail, Postbox, or Other
property fromAddress : "" --only works with Mail.app
property subjectSuffix : " !!!" --appended to the email subject
property bodySuffix : "

#End"

(*
	# CHANGE HISTORY #
	
	2.3.1 (2015-07-19)
		- Processes each email separately
		- Task note used for email body
		- Updates to date processing
		- Email subject suffix is 
	
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
				-- Email subject
				set theTitle to name of thisItem
				try
					set theSubject to theTitle & " @" & (name of context of thisItem)
				on error
					set theSubject to theTitle
				end try
				try
					set theDate to due date of thisItem
					set theDueDateString to (my pyFormatTime(theDate, "[%m/%d/%Y]"))
					set theSubject to theSubject & " " & theDueDateString & subjectSuffix
				on error
					set theSubject to theSubject & subjectSuffix
				end try
				
				-- Email recipient
				try
					set theParentName to (my replace_chars(" ", "", (name of containing project of thisItem)))
				on error
					display dialog theTitle & " has no containing project. Please enter a project name:" default answer "akw"
					set theParentName to text returned of result
				end try
				set theRecipient to theParentName & "@tasks.teamwork.com"
				
				-- Email body
				set theBody to (note of contents of thisItem) & bodySuffix
				my sendMessage(theRecipient, theSubject, theBody)
			end repeat
		end tell
	end tell
end main

on sendMessage(emailRecipient, emailSubject, emailBody)
	if mailClient = "Mail" then
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
	else if mailClient = "Postbox" then
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

on pyFormatTime(AS_Date, AS_Format)
	set timeFormat to quoted form of AS_Format
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
