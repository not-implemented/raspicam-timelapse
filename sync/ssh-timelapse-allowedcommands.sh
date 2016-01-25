#!/bin/bash
# modified version of https://www.thomas-krenn.com/de/wiki/Ausf%C3%BChrbare_SSH-Kommandos_per_authorized_keys_einschr%C3%A4nken
#Use the original command as positional parameter
set "$SSH_ORIGINAL_COMMAND"

if [[ "$SSH_ORIGINAL_COMMAND" =~ [\&\;] ]] ;
then
    echo "Error: Invalid character found in command."
    exit 1
fi

case "$SSH_ORIGINAL_COMMAND" in
    rsync*/timelapse/capture*)
        ;;
    *)
        echo "Error: Invalid command over ssh executed."
        exit 1
        ;;
esac

exec $SSH_ORIGINAL_COMMAND
