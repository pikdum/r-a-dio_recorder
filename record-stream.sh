#!/usr/bin/env bash
set -eo pipefail

is_streaming() {
    local response=$(curl -s https://r-a-d.io/api | jq -r '.main.isafkstream')
    [[ "$response" != "true" ]]
}

is_recording() {
    [[ -n "$pid" ]] && [[ -n $(ps -p $pid -o pid=) ]]
}

while true; do
    if is_streaming && ! is_recording; then
        echo "Stream is active; recording started."
        wget https://stream.r-a-d.io/main.mp3 -O "r-a-dio_$(date +"%Y-%m-%dT%H-%M-%S-%3N").mp3" >/dev/null 2>&1 &
        pid=$!
    elif ! is_streaming && is_recording; then
        echo "Stream is not active; recording stopped."
        kill $pid
        pid=""
    else
        echo "Waiting until stream is active..."
        sleep 30
    fi
done
