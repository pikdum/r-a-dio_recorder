#!/usr/bin/env bash
set -euxo pipefail

scp record-stream.sh root@files.usagi.zone:/usr/local/bin/
scp record-stream.service root@files.usagi.zone:/etc/systemd/system/
ssh root@files.usagi.zone 'systemctl daemon-reload && systemctl restart record-stream'
