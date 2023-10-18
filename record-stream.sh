#!/usr/bin/env bash
set -eo pipefail

is_streaming() {
    [ "$DEBUG" = true ] && [ -e "is_streaming" ] && return 0
    curl -s https://r-a-d.io/api | jq -e '.main.isafkstream == false' >/dev/null
}

is_recording() {
    [ "$DEBUG" = true ] && [ -e "is_recording" ] && return 0
    [[ -n "$pid" ]] && [[ -n $(ps -p $pid -o pid=) ]]
}

start_recording() {
    recording="r-a-dio_$(date +"%Y-%m-%dT%H-%M-%S-%3N").mp3"
    log="${recording}.log"
    wget https://stream.r-a-d.io/main.mp3 -O "$recording" >/dev/null 2>&1 &
    pid=$!
}

stop_recording() {
    [ -n "$pid" ] && kill "$pid" || true
}

append_lp_log() {
    curl -s https://r-a-d.io/api | jq -r '.main.lp[] | "\(.timestamp): \(.meta)"' >>"$log"
    sort -u -o "$log" "$log"
}

trap stop_recording EXIT

while true; do
    if ! is_recording && is_streaming; then
        start_recording
        echo "Recording started: $recording"
        append_lp_log
    elif is_recording && ! is_streaming; then
        stop_recording
        echo "Recording stopped: $recording"
        append_lp_log
    elif is_recording && is_streaming; then
        append_lp_log
    fi
    sleep 60
done
