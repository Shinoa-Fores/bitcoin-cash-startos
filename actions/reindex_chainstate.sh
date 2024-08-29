#!/bin/sh

set -e

action_result_running="    {
    \"version\": \"0\",
    \"message\": \"Bitcoin Cash restarting in reindex chainstate mode\",
    \"value\": null,
    \"copyable\": false,
    \"qr\": false
}"
action_result_stopped="    {
    \"version\": \"0\",
    \"message\": \"Bitcoin Cash will reindex the chainstate the next time the service is started\",
    \"value\": null,
    \"copyable\": false,
    \"qr\": false
}"



touch /root/.bitcoin/requires.reindex_chainstate
bitcoin-cli -rpcconnect=bitcoind.embassy stop >/dev/null 2>/dev/null && echo $action_result_running || echo $action_result_stopped

