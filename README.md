# tsrcontrol
Control Script for Twitch-Stream-Recorder (tsr.py)

This script is a Bash script that is used to control a Twitch stream recorder. 
It has several functions, such as creating, enabling, disabling, starting, stopping, 
and deleting individual or all stream recorders. 
The script prompts the user to enter a non-root username to run the tsr.py script as, 
and this information is stored in the file ~/.tsrconf for future use. 
The script uses the systemd service management tool to manage the stream recorder services. 
It also includes a function to display the active stream recorders.
