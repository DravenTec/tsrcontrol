# tsrcontrol
Control Script for Twitch-Stream-Recorder (tsr.py)


WARNING: This script is still under development and may contain errors and incompleteness. 
Use it at your own risk and we assume no liability for any damage or loss of data that may 
result from the use of the script. Please use the script only if you agree with the risks and 
limitations. We welcome feedback and bug reports to further improve the script.



This script is a Bash script that is used to control a Twitch stream recorder. 
It has several functions, such as creating, enabling, disabling, starting, stopping, 
and deleting individual or all stream recorders. 
The script prompts the user to enter a non-root username to run the tsr.py script as, 
and this information is stored in the file ~/.tsrconf for future use. 
The script uses the systemd service management tool to manage the stream recorder services. 
It also includes a function to display the active stream recorders.
