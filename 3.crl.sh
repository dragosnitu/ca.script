#!/bin/bash

. ./config
cd $ROOT_DIR

openssl ca -config ./openssl.cnf -gencrl -out CA/crl/ca.crl -name CA_root -passin pass:"$PASS"
openssl crl -in CA/crl/ca.crl -noout -text

# Test with:
#openssl verify -crl_check -CAfile CA/crl/ca.crl tls/certs/computer1@digired.ro.crt

