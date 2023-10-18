#!/usr/bin/env bash
set -eo pipefail

is_streaming() {
    [ "$DEBUG" = true ] && [ -e "is_streaming" ] && return 0
    local response=$(curl -s https://r-a-d.io/api | jq -r '.main.isafkstream')
    [[ "$response" != "true" ]]
}

is_recording() {
    [ "$DEBUG" = true ] && [ -e "is_recording" ] && return 0
    [[ -n "$pid" ]] && [[ -n $(ps -p $pid -o pid=) ]]
}

append_lp_log() {
    local lp_file="$1"
    curl -s https://r-a-d.io/api | jq -r '.main.lp[] | "\(.timestamp): \(.meta)"' >>"$lp_file"
    sort -u -o "$lp_file" "$lp_file"
}

while true; do
    if is_streaming && ! is_recording; then
        echo "Recording started."

        recording="r-a-dio_$(date +"%Y-%m-%dT%H-%M-%S-%3N").mp3"
        log="${recording}.log"
        touch "$log"

        wget https://stream.r-a-d.io/main.mp3 -O "$recording" >/dev/null 2>&1 &
        pid=$!

        append_lp_log "$log"
    elif is_streaming && is_recording; then
        append_lp_log "$log"
    elif ! is_streaming && is_recording; then
        echo "Recording stopped."
        append_lp_log "$log"
        kill $pid
        pid=""
    fi
    sleep 60
done
