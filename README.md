![GitHub](https://img.shields.io/github/license/DravenTec/tsrcontrol)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/DravenTec/tsrcontrol)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/DravenTec/tsrcontrol)

# Twitch Stream Recorder - Control Script

This script provides control functionalities for managing Twitch stream recording. 
It allows you to create, enable, disable, start, stop, restart and view the status of stream recorders.

## Prerequisites

- Bash (Bourne Again SHell)
- `systemctl` command (available on most Linux distributions)
- Python 3 with `tsr.py` script located in the home directory of the non-root user specified

## Getting Started

1. Clone the repository: `git clone https://github.com/DravenTec/tsrcontrol`
2. Navigate to the script directory: `cd tsrcontrol`
3. Make the script executable: `chmod +x tsrcontrol.sh`
4. Run the script: `./tsrcontrol.sh`

## Usage

The script presents a menu with the following options:

1. Enable: Enable a specific stream recorder or all known recorders.
2. Disable: Disable a specific stream recorder or all known recorders.
3. Start: Start a specific stream recorder or all known recorders.
4. Stop: Stop a specific stream recorder or all known recorders.
5. Status: View the status of a specific stream recorder or all known recorders.
6. Create service: Create a new stream recorder service.
7. Active recorder: View the currently active stream recorder.
8. Delete recorder: Delete a specific stream recorder and its associated service.
9. Quit: Exit the script.

Follow the on-screen instructions and provide the required inputs to perform the desired action.

## Configuration

The script uses a configuration file located at `~/.tsrconf` to store the non-root user and the list of known stream recorders. 
If the configuration file doesn't exist, it will be created on the first run.

## License

This script is licensed under the [MIT License](LICENSE).


WARNING: This script is still under development and may contain errors and incompleteness. 
Use it at your own risk and we assume no liability for any damage or loss of data that may 
result from the use of the script. Please use the script only if you agree with the risks and 
limitations. We welcome feedback and bug reports to further improve the script.



