#!/bin/bash
#
# Twitch Stream Recorder - Automatic Run
#

# systemctl enable/disable/start/stop/status
sys_enable="systemctl enable"
sys_disable="systemctl disable"
sys_start="systemctl start"
sys_status="systemctl status"
sys_stop="systemctl stop"

# Active Stream Recorder
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

enable_streams () {
    clear
    echo ""
    echo "Enable Recorder"
    S3="Please enter your choice"
    select stream_recorder in $streams All Quit
    do
    if [[ $stream_recorder != All ]] && [[ $stream_recorder != Quit ]];
    then
        $sys_enable $stream_recorder
    else
       if [[ $stream_recorder == All ]]; then $sys_enable $streams; fi
       if [[ $stream_recorder == Quit ]]; then break; fi
    fi
    done
}

disable_streams () {
    clear
    echo ""
    echo "Disable Recorder"
    S3="Please enter your choice"
    select stream_recorder in $streams All Quit
    do
    if [[ $stream_recorder != All ]] && [[ $stream_recorder != Quit ]];
    then
        $sys_disable $stream_recorder
    else
       if [[ $stream_recorder == All ]]; then $sys_disable $streams; fi
       if [[ $stream_recorder == Quit ]]; then break; fi
    fi
    done
}

start_streams () {
    clear
    echo ""
    echo "Start Recorder:"
    S3="Please enter your choice"
    select stream_recorder in $streams All Quit
    do
    if [[ $stream_recorder != All ]] && [[ $stream_recorder != Quit ]];
    then
        $sys_start $stream_recorder
    else
       if [[ $stream_recorder == All ]]; then $sys_start $streams; fi
       if [[ $stream_recorder == Quit ]]; then break; fi
    fi
    done

}

stop_streams () {
    clear
    echo ""
    echo "Stop Recorder: $sys_stop $streams"
    S3="Please enter your choice"
    select stream_recorder in $streams All Quit
    do
    if [[ $stream_recorder != All ]] && [[ $stream_recorder != Quit ]];
    then
        $sys_stop $stream_recorder
    else
       if [[ $stream_recorder == All ]]; then $sys_stop $streams; fi
       if [[ $stream_recorder == Quit ]]; then break; fi
    fi
    done

}

status_streams () {
    clear
    echo ""
    echo "Status Recorder: $sys_status $streams"
    $sys_status $streams
    echo ""
    echo "Press any key to continue"
    read;
}

show_recorder () {
    clear
    echo ""
    echo "Active recorders:"
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
    echo "Please enter your choice"
    echo ""
    echo "Active Records: $streams"
    echo ""
    select opt in "${options[@]}"; do
        case $opt in
            "Enable") enable_streams; break ;;
            "Disable") disable_streams; break ;;
            "Start") start_streams; break ;;
            "Stop") stop_streams; break ;;
            "Status") status_streams; break ;;
            "Create Service") create_service; break ;;
            "Active Records") show_recorder; break ;;
            "Quit") clear; break 2 ;;
            *) echo "Invalid input"
        esac
    done
done
