#!/usr/bin/env bash
set -eo pipefail

name="r-a-dio"
api="https://r-a-d.io/api"
stream="https://r-a-d.io/assets/main.mp3.m3u"

is_streaming() {
    [ "$DEBUG" = true ] && [ -e "is_streaming" ] && return 0
    echo "$data" | jq -e '.main.isafkstream == false' >/dev/null
}

is_recording() {
    [ "$DEBUG" = true ] && [ -e "is_recording" ] && return 0
    [[ -n "$pid" ]] && [[ -n $(ps -p $pid -o pid=) ]]
}

start_recording() {
    recording="${name}_$(date +"%Y-%m-%dT%H-%M-%S-%3N").mp3.m3u"
    log="${recording}.log"
    wget "$stream" -O "$recording" >/dev/null 2>&1 &
    pid=$!
    start_time=$(echo "$data" | jq -r '.main.current')
}

stop_recording() {
    [ -n "$pid" ] && kill "$pid" || true
}

log_songs() {
    echo "$data" | jq -r --arg start_time "$start_time" '.main.lp[] | select(.timestamp >= ($start_time | tonumber)) | "\(.timestamp): \(.meta)"' >>"$log"
    echo "$data" | jq -r '.main | "\(.end_time): \(.np)"' >>"$log"
    sort -u -o "$log" "$log"
    awk -F ': ' '{ lines[tolower($2)] = $0 } END { for (i in lines) { print lines[i] } }' "$log" >/tmp/song-log && mv /tmp/song-log "$log"
    sort -u -o "$log" "$log"
}

log_dj() {
    new_dj=$(echo "$data" | jq -r '.main.dj.djname')
    if [ "$new_dj" != "$old_dj" ]; then
        echo "$(date +%s): *DJ* $new_dj" >>"$log"
    fi
    old_dj=$new_dj
}

trap stop_recording EXIT

while true; do
    data=$(curl -s "$api")
    if ! is_recording && is_streaming; then
        start_recording
        echo "Recording started: $recording"
        log_dj
        log_songs
    elif is_recording && ! is_streaming; then
        stop_recording
        echo "Recording stopped: $recording"
        log_songs
    elif is_recording && is_streaming; then
        log_dj
        log_songs
    fi
    sleep 60
done
