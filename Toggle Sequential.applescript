(*
	# DESCRIPTION #
	
	Toggles whether the selected item is sequential or parallel. Thanks to Brandon Pittman for your javascript-based version: https://gist.github.com/brandonpittman/c826c9feddf9eeb094eb	
	
	
	# LICENSE #

	Copyright © 2015-2017 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	(TL;DR: no warranty, do whatever you want with it.)
	

	# CHANGE HISTORY#
	
	2015-05-17
	-	Initial release

*)


tell application "OmniFocus"
	tell content of first document window of front document
		set validSelectedItemsList to value of (selected trees where class of its value is not item and class of its value is not folder and class of its value is not context and class of its value is not perspective)
		if (count of validSelectedItemsList) is 0 then return
		
		set autosave to false
		repeat with thisItem in validSelectedItemsList
			if sequential of thisItem is false then
				set sequential of thisItem to true
			else
				set sequential of thisItem to false
			end if
		end repeat
		set autosave to true
	end tell
end tell
