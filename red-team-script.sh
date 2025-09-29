#!/bin/bash

# Script to run red team every 30 seconds from 11:59 PM to 11:59:59 PM

while true; do
    current_time=$(date +"%H:%M")
    if [ "$current_time" == "23:59" ]; then
        # Run your red team command here
        ./run-red-team.sh

        # Wait for 30 seconds before running again
        sleep 30
    else
        # Sleep until 11:59 PM
        sleep 10
    fi
done