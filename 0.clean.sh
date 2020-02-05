#!/bin/bash

. ./config

cd $ROOT_DIR
rm -rf CA/ log/ tls/ ca.crl configs/*.ovpn openssl.cnf >&/dev/null
