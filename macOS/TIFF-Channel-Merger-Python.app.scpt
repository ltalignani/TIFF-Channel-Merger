#!/usr/bin/osascript
-- TIFF Channel Merger Launcher
-- Launches Python/Tkinter GUI

on run
	set scriptPath to POSIX path of (path to me)
	set scriptDir to do shell script "dirname " & quoted form of scriptPath
	set pythonScript to scriptDir & "/tiff_channel_merger_gui.py"

	try
		-- Check if Python script exists
		do shell script "test -f " & quoted form of pythonScript

		-- Launch Python GUI in background
		do shell script "cd " & quoted form of scriptDir & " && /usr/bin/python3 " & quoted form of pythonScript & " > /dev/null 2>&1 &"

	on error errMsg
		display dialog "Erreur au lancement de TIFF Channel Merger:

" & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end run
