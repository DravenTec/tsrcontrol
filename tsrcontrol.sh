#!/bin/bash
#
# Twitch Stream Recorder - Control Script
#
# Version: 0.9.0
#
# Developed by: DravenTec
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
        read -rp "Please specify the non-root user to run tsr.py: " input_username
        declare -Ag streams
        user="$input_username"
        echo "declare -Ag streams" > ~/.tsrconf
        echo "user=$input_username" >> ~/.tsrconf
fi


create_menu () {
    clear
    echo ""
    echo "$3 recorder"
    echo ""
    select stream_recorder in "${!streams[@]}" "All" "Quit"
    do
      case $stream_recorder in
          "All") echo "$3 all known recorder"; $1 $2 "${streams[@]}";;
          "Quit") break ;;
          "") echo "Invalid input" ;;
          *) echo "$3 recorder $stream_recorder"; $1 $2 "$stream_recorder";;
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

	streams["$streamer"]="1"

	echo "declare -Ag streams" > ~/.tsrconf
	echo "user=$user" >> ~/.tsrconf
	for stream in "${!streams[@]}"; do
	  echo "streams[\"$stream\"]=\"${streams[$stream]}\"" >> ~/.tsrconf
	done

	echo "Enabling Streamrecorder for $streamer"
        $sys_enable $streamer
        echo "Starting Streamrecorder for $streamer"
        $sys_start $streamer
        echo "Press any key to continue"
        read;
}

delete_service () {
        clear
        echo ""
        select streamer in ${!streams[@]} Quit
        do
          case $streamer in
              Quit) break ;;
              "") echo "Invalid input" ;;
              *) echo "Deleting Streamrecorder for $streamer";
                 $sys_stop $streamer
                 $sys_disable $streamer
                 rm /etc/systemd/system/$streamer.service

				 echo "declare -Ag streams" > ~/.tsrconf
                 echo "user=$user" >> ~/.tsrconf

                 unset streams["$streamer"]
                 new_streams=""
                 for stream in "${!streams[@]}"; do
	                echo "streams[\"$stream\"]=\"${streams[$stream]}\"" >> ~/.tsrconf
                 done
                 echo "Streamrecorder for $streamer deleted."
                 break;;
          esac
        done
}


while true; do
    clear
    options=("Enable" "Disable" "Start" "Stop" "Status" "Create service" "Active recorder" "Delete recorder" "Quit")
    echo ""
    echo "Known recorder: ${!streams[@]}"
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
			"Delete recorder") delete_service; break ;;
            "Quit") clear; break 2 ;;
            *) echo "Invalid input"
        esac
    done
done
