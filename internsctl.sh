#!/bin/bash

# Function to display the manual page for internsctl
function display_manual() {
    echo "MANUAL PAGE"
    echo "..."

}

function display_help() {
    echo "Usage: internsctl [COMMAND]"
    echo " "
    echo "Commands:"
    echo "  cpu getinfo               Get CPU information"
    echo "  memory getinfo            Get memory information"
    echo "  user create <username>    Create a new user"
    echo "  user list                 List all regular users"
    echo "  user list --sudo-only     List users with sudo permissions"
    echo "  file getinfo <file-name>  Get information about a file"
    echo "  --help                    Display help and usage guidelines"
    echo "  --version                 Display command version"
}

function display_version() {
    echo "internsctl v0.1.0"
}

function create_user() {
    if [ -z "$1" ]; then
        echo "Error: Username not provided."
        return 1
    fi

    username=$1


    if id "$username" &>/dev/null; then
        echo "User '$username' already exists."
        return 1
    fi

    sudo useradd -m "$username"

    sudo passwd "$username"

    echo "User '$username' created successfully."
}

function handle_command() {
    case "$1" in
        "cpu" )
            if [ "$2" == "getinfo" ]; then
                lscpu
            fi
            ;;
        "memory" )
            if [ "$2" == "getinfo" ]; then
                free
            fi
            ;;
        "user" )
            case "$2" in
                "create" )
                    create_user "$3"
                    ;;
                "list" )
                    if [ "$3" == "--sudo-only" ]; then
                       sudo grep -Po '^sudo.+:\K.*$' /etc/group | cut -d: -f4 | tr ',' '\n'
                    else
                        getent passwd | cut -d: -f1
                    fi
                    ;;
                * )
                    echo "Invalid command for user management."
		    ;;
            esac
            ;;
        "file" )
	    if [ "$2" == "getinfo" ]; then
                shift 2 # Shift to the next arguments after "file getinfo"
                filename=""
                options=""


                while [[ $# -gt 0 ]]; do
                    case "$1" in
                        "--size" | "-s" | "--permissions" | "-p" | "--owner" | "-o" | "--last-modified" | "-m" )
                            options+=" $1"
                            shift
                            ;;
                        * )
                            filename="$1"
                            shift
                            break
                            ;;
                    esac
                done

                if [ -z "$filename" ]; then
                    echo "Error: File name not provided."
                    return 1
                fi

                if [ ! -f "$filename" ]; then
                    echo "File '$filename' not found."
                    return 1
                fi
                file_info="File: $filename"
        	file_info+="\nAccess: $(stat -c %A "$filename")"
        	file_info+="\nSize(B): $(stat -c %s "$filename")"
        	file_info+="\nOwner: $(stat -c %U "$filename")"
        	file_info+="\nModify: $(stat -c %y "$filename")"

                case "$options" in
                    *" --size" | *" -s" )
                        echo "$(stat -c %s "$filename")"
                        ;;
                    *" --permissions" | *" -p" )
                        echo "$(stat -c %A "$filename")"
                        ;;
                    *" --owner" | *" -o" )
                        echo "$(stat -c %U "$filename")"
                        ;;
                    *" --last-modified" | *" -m" )
                        echo "$(stat -c %y "$filename")"
                        ;;
                    * )
                        echo -e "$file_info"
                        ;;
                esac
            else
                echo "Invalid command"
                return 1
            fi
            ;;
        * )
            echo "Command not recognized. Use 'internsctl --help' for usage guidelines."
            ;;
    esac
}


function main() {
    if [ "$1" == "--help" ]; then
        display_help
    elif [ "$1" == "--version" ]; then
        display_version
    else
        handle_command "$@"
    fi
}

# Entry point of the script
main "$@"

