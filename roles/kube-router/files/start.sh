#!/bin/bash
sleep 10
ip link delete kube-dummy-if type bridge
ip link delete kube-bridge type bridge
supervisord -c supervisord.conf
