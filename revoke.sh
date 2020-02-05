#!/bin/bash

. ./config
cd $ROOT_DIR

if [ -z "$1" ]; then
    echo -n "Enter domain name or email address: "
    read DOMAIN
else
    DOMAIN=$1
fi

echo "$DOMAIN" | grep @ >&/dev/null && EXT=usr_cert || EXT=server_cert
echo "$DOMAIN" | grep @ >&/dev/null && EMAIL=$DOMAIN || EMAIL=noc@$DOMAIN

echo "You are about to revoke certificate for $DOMAIN ($EXT). Press ENTER to continue, CTRL+C to cancel"
read

if [ ! -f tls/certs/$DOMAIN.crt ]; then
    echo Certificate does not exist
    exit
fi

openssl ca -batch -config openssl.cnf -revoke tls/certs/$DOMAIN.crt -name CA_root -passin pass:"$PASS"
TEST=$?
if [ "$TEST" = 0 ]; then
    echo Certificate revoked
else
    echo Certificate revocation failed
    exit
fi

openssl ca -config ./openssl.cnf -gencrl -out CA/crl/ca.crl -passin pass:"$PASS"
TEST=$?
if [ "$TEST" = 0 ]; then
    echo CRL regenerated
else
    echo CRL generation failed
    exit
fi
openssl crl -in CA/crl/ca.crl -noout -text
