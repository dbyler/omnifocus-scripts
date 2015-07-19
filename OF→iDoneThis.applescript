(*
	Email Selected Tasks to iDoneThis
	
	# DESCRIPTION #
	
	This script generates an email from selected OmniFocus tasks to send to iDoneThis. Each task title is presented on a separate line.
	
	# LICENSE #
	
	Copyright 2014-2015 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)
	
	# CHANGE HISTORY #

	1.0 (2015-07-19) Original release

	
	# INSTALLATION #

	- 	Copy this script to OmniFocus scripts folder
		- To find this, in OmniFocus, go to Help -> Open Scripts Folder
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar...
		
*)-- To change settings, modify the following propertiesproperty defaultRecipient : "personal-diary-ihm6@team.idonethis.com"property fromAddress : ""property mailClient : "Mail" --options: Mail, Postbox, or Otherproperty includeProject : true --if true, includes the task's Project title in bracketson main()	set email_list to {}		tell application "OmniFocus"		tell content of front document window of front document			--Get selection			set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder)			set totalItems to count of validSelectedItemsList			if totalItems is 0 then				my notifyWithoutGrowl("No valid task(s) selected")				return			end if						set theSubject to my pyFormatTime(current date, "%A, %B %e")			set theRecipient to defaultRecipient			set theBody to ""						repeat with thisItem in validSelectedItemsList				set theTitle to name of thisItem								if includeProject then					try						set theParentName to (name of containing project of thisItem)						set theTitle to theTitle & " [" & theParentName & "]"					end try				end if								set theBody to theBody & theTitle & "
"			end repeat			my sendMessage(theRecipient, theSubject, theBody)		end tell	end tellend mainon sendMessage(emailRecipient, emailSubject, emailBody)	if mailClient = "Mail" then		tell application "Mail"			activate			set theOutMessage to make new outgoing message with properties {visible:true}			tell theOutMessage				make new to recipient at end of to recipients with properties {address:emailRecipient}				set sender to fromAddress				set subject to emailSubject				set content to emailBody			end tell		end tell	else if mailClient = "Postbox" then		tell application "Postbox"			activate			send message subject emailSubject body emailBody recipient emailRecipient		end tell	else		set emailSubject to (my replace_chars("&", "–", emailSubject))		set emailBody to (my replace_chars("&", "–", emailBody))		tell application "System Events" to open location "mailto:" & emailRecipient & "?subject=" & emailSubject & "&body=" & emailBody	end ifend sendMessageon pyFormatTime(AS_Date, AS_Format)	set timeFormat to quoted form of AS_Format	return (do shell script "/usr/bin/python -c \"import time, dateutil.parser; print dateutil.parser.parse('" & AS_Date & "').strftime(" & timeFormat & "); \"")end pyFormatTimeon replace_chars(search_string, replacement_string, this_text)	set AppleScript's text item delimiters to the search_string	set the item_list to every text item of this_text	set AppleScript's text item delimiters to the replacement_string	set this_text to the item_list as string	set AppleScript's text item delimiters to ""	return this_textend replace_charson notifyWithoutGrowl(alertText)	tell application "OmniFocus" to display dialog alertText with icon 1 buttons {"OK"} default button "OK"end notifyWithoutGrowlmain()