#!/bin/bash
#
# Twitch Stream Recorder - Control Script
#
# Version: 01.06.2023 (0025)
#
# Developed by: DravenTec
#
# Create, Enable, Disable, Start, Stop Recorder

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
    local selected_recorder
    while true; do
        clear
        echo ""
        echo "$3 recorder"
        echo ""
        select stream_recorder in $streams All Quit
        do
            case $stream_recorder in
                All) echo "$3 all known recorder"; selected_recorder="all"; break ;;
                Quit) selected_recorder="quit"; break ;;
                "") echo "Invalid input" ;;
                *) echo "$3 recorder $stream_recorder"; selected_recorder=$stream_recorder; break ;;
            esac
        done

        # Überprüfen, ob das Menü erneut angezeigt werden soll
        if [[ $selected_recorder != "quit" ]]; then
            if [[ $selected_recorder == "all" ]]; then
                $1 $2 $streams
            else
                $1 $2 $selected_recorder
            fi

            read -n 1 -s -r -p "Press any key to continue"
        else
            break
        fi
    done

}

show_recorder () {
    clear
    echo ""
    echo "Active recorder:"
    ps ax | grep tsr.py | head -n -1
    echo ""
    read -n 1 -s -r -p "Press any key to continue"
}

create_service () {
    clear
    echo ""
    read  -p "Please enter streamers name in lowercase: " streamer
    if [[ -z $streamer ]]; then
        echo "Invalid input. Streamer's name cannot be empty."
        read -n 1 -s -r -p "Press any key to continue"
        return
    fi
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
    read -n 1 -s -r -p "Press any key to continue"
}

delete_menu () {
    local selected_recorder
    while true; do
        clear
        echo ""
        echo "Delete recorder and service"
        echo ""
        select stream_recorder in $streams Quit
          do
           case $stream_recorder in
              Quit) selected_recorder="quit"; break 2 ;;
              "") echo "Invalid input" ;;
              *) echo "Delete recorder $stream_recorder"; delete_recorder $stream_recorder; break ;;
           esac
        done

        if [[ $selected_recorder != "quit" ]]; then
            read -n 1 -s -r -p "Press any key to continue"
        else
            break
        fi
    done
}

delete_recorder () {
    echo ""
    echo "Stop and disable recorder..."
    $sys_stop $1
    $sys_disable $1
    echo "Remove service file ..."
    rm /etc/systemd/system/$1.service
    echo "Removing $1 from streamer list..."
    streams=("${streams[@]/$1}")
    updated_streams=$(IFS=" " ; echo "${streams[*]}" | sed 's/^ *//;s/ *$//')
    updated_streams=$(echo "$updated_streams" | tr -s ' ' | sed 's/  / /g')
    echo "Saving new streamer list ..."
    sed -i "s/streams=\".*\"/streams=\"$updated_streams\"/g" ~/.tsrconf
}

while true; do
    clear
    options=("Enable" "Disable" "Start" "Stop" "Status" "Create service" "Active recorder" "Delete recorder" "Quit")
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
                        "Delete recorder") delete_menu; break;;
            "Quit") clear; break 2 ;;
            *) echo "Invalid input"
        esac
    done
done
