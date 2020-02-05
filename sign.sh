#!/bin/bash

. ./config
cd $ROOT_DIR
mkdir -p tls/{certs,private}
chmod 700 tls/private

if [ -z "$1" ]; then
    echo -n "Enter domain name or email address: "
    read DOMAIN
else
    DOMAIN=$1
fi

echo "$DOMAIN" | grep @ >&/dev/null && EXT=usr_cert || EXT=server_cert
echo "$DOMAIN" | grep @ >&/dev/null && EMAIL=$DOMAIN || EMAIL=noc@$DOMAIN
echo "$DOMAIN" | grep @ >&/dev/null || openssl dhparam -out tls/certs/$DOMAIN-dhparam.pem 2048

echo "Generating key&certificate pair for $DOMAIN ($EXT). Press ENTER to continue, CTRL+C to cancel"
read

openssl genpkey -algorithm RSA -out tls/private/$DOMAIN.key -pkeyopt rsa_keygen_bits:2048
TEST=$?
if [ "$TEST" = "0" ]; then
    echo Private key generated in tls/private/$DOMAIN.key
else
    echo Generating private key failed
    exit
fi
chmod 400 tls/private/$DOMAIN.key

openssl req -config ./openssl.cnf -new -sha256 \
      -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$COMPANY/OU=Networking/CN=$DOMAIN/emailAddress=$EMAIL" \
      -key tls/private/$DOMAIN.key \
      -out CA/csr/$DOMAIN.csr
TEST=$?
if [ "$TEST" = "0" ]; then
    echo CSR generated
else
    echo CSR FAILED
    exit
fi

openssl ca -batch -config openssl.cnf -extensions $EXT \
      -days $DAYS_CERT -notext -md sha256 \
      -in CA/csr/$DOMAIN.csr \
      -out tls/certs/$DOMAIN.crt \
      -passin pass:"$PASS"
TEST=$?
if [ "$TEST" = "0" ]; then
    echo Certificate signed: tls/certs/$DOMAIN.crt
    echo -e "Check the certificate with:\n\topenssl x509 -noout -text -in tls/certs/$DOMAIN.crt\n\topenssl verify -CAfile CA/certs/ca$INTERMEDIATE-chain.crt tls/certs/$DOMAIN.crt"
    cat tls/certs/$DOMAIN.crt >tls/certs/$DOMAIN-chain.crt
    cat CA/certs/ca$INTERMEDIATE-chain.crt >>tls/certs/$DOMAIN-chain.crt
else
    echo Certificate signed failed
    exit
fi
chmod 444 tls/certs/$DOMAIN.crt

sh ./openvpn.sh $DOMAIN
