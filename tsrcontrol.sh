#!/bin/bash
#
# Twitch Stream Recorder - Control Script
#
# Create, Enable, Disable, Start, Stop Recorder
#

# systemctl enable/disable/start/stop/status
sys_enable="systemctl enable"
sys_disable="systemctl disable"
sys_start="systemctl start"
sys_status="systemctl status"
sys_stop="systemctl stop"

# Global Settings
PS3="Please enter your choice: "

# Known Stream Recorder
if [ -f ~/.tsrconf ]; then
        source ~/.tsrconf
else
        read  -p "Please specify the non-root user to run tsr.py: " input_username
	cat <<-EOFC >> ~/.tsrconf
	user="$input_username"
	streams=""
	EOFC
	source ~/.tsrconf
fi

create_menu () {
    clear
    echo "" 
    echo "$3 recorder"
    echo ""
    select stream_recorder in $streams All Quit
    do
      case $stream_recorder in
          All) echo "$3 all known recorder"; $1 $2 $streams;;
          Quit) break ;;
          "") echo "Invalid input" ;;
          *) echo "$3 recorder $stream_recorder"; $1 $2 $stream_recorder;;
      esac
    done
}

show_recorder () {
    clear
    echo ""
    echo "Active recorder:"
    ps ax | grep tsr.py | head -n -1
    echo ""
    echo "Press any key to continue"
    read;
}

create_service () {
        clear
        echo ""
        read  -p "Please enter streamers name in lowercase: " streamer
        echo "tsr.py must be located under /home/$user/"
	echo ""
	cat <<-EOF >> /etc/systemd/system/$streamer.service
	[Unit]
	Description=$streamer Recorder
	After=syslog.target
	
	[Service]
	Type=simple
	User=$user
	Group=$user
	WorkingDirectory=/home/$user
	ExecStart=/usr/bin/python3 tsr.py -u $streamer
	SyslogIdentifier=$streamer
	StandardOutput=syslog
	StandardError=syslog
	Restart=always
	RestartSec=3
	
	[Install]
	WantedBy=multi-user.target
	EOF

        sed -i "s/streams=\"$streams\"/streams=\"$streams $streamer\"/g" ~/.tsrconf
        echo "Enabling Streamrecorder for $streamer"
        $sys_enable $streamer
        echo "Starting Streamrecorder for $streamer"
        $sys_start $streamer
        streams="$streams $streamer"
        echo "Press any key to continue"
        read;
}

while true; do
    clear
    options=("Enable" "Disable" "Start" "Stop" "Status" "Create Service" "Active Records" "Quit")
    echo ""
    echo "Known recorder: $streams"
    echo ""
    select opt in "${options[@]}"; do
        case $opt in
            "Enable") create_menu $sys_enable Enable; break ;;
            "Disable") create_menu $sys_disable Disable; break ;;
            "Start") create_menu $sys_start Start; break ;;
            "Stop") create_menu $sys_stop Stop; break ;;
            "Status") create_menu $sys_status Status; break ;;
            "Create service") create_service; break ;;
            "Active recorder") show_recorder; break ;;
            "Quit") clear; break 2 ;;
            *) echo "Invalid input"
        esac
    done
done
