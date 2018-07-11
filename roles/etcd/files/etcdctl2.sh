#!/bin/bash
ETCDCTL_API=2 ./bin/etcdctl --endpoints=https://127.0.0.1:2379 --ca-file=./cert/ca/ca.pem --key-file=./cert/client/key.pem --cert-file=./cert/client/cert.pem $*
