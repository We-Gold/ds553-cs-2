#!/bin/bash

# Script to run red team every 30 seconds from 11:59 PM to 12:01 AM

while true; do
    current_time=$(date +"%H:%M")
    if [ "$current_time" == "23:59" ] || [ "$current_time" == "00:00" ]; then
        # Run your red team command here
        ./run-red-team.sh

        # Wait for 30 seconds before running again
        sleep 30
    elif [ "$current_time" == "00:01" ]; then
        # Stop running at 12:01 AM
        break
    else
        # Sleep until the next check
        sleep 10
    fi
done