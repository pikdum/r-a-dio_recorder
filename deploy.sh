#!/usr/bin/env bash
set -euxo pipefail

scp record-stream.sh root@yui.usagi.zone:/usr/local/bin/record-radio.sh
scp record-stream.service root@yui.usagi.zone:/etc/systemd/system/record-radio.service
ssh root@yui.usagi.zone 'systemctl daemon-reload && systemctl restart record-radio'
