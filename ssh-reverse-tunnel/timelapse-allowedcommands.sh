#!/bin/bash

if [[ "$SSH_ORIGINAL_COMMAND" =~ [\&\;] ]] ;
then
    echo "Error: Invalid character found in command."
    exit 1
fi

case "$SSH_ORIGINAL_COMMAND" in
    rsync*/path/to/capture/sync*)
        ;;
    *)
        echo "Error: Invalid command over ssh executed."
        exit 1
        ;;
esac

exec $SSH_ORIGINAL_COMMAND
