#!/bin/bash

. ./config
cd $ROOT_DIR
mkdir -p tls/private

openssl genpkey -algorithm RSA -out CA/private/ca$INTERMEDIATE.key -pkeyopt rsa_keygen_bits:$BITS -aes-256-cbc -pass pass:"$PASS"
chmod 400 CA/private/ca$INTERMEDIATE.key

openssl req -config ./openssl.cnf -new -$SHA \
      -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$COMPANY/OU=Networking/CN=$COMPANY Intermediate CA $INTERMEDIATE" \
      -key CA/private/ca$INTERMEDIATE.key \
      -out CA/csr/ca$INTERMEDIATE.csr \
      -passin pass:"$PASS"

openssl ca -batch -config openssl.cnf -extensions v3_int_ca -name CA_root \
      -days $DAYS_ROOT -notext -md $SHA \
      -in CA/csr/ca$INTERMEDIATE.csr \
      -out CA/certs/ca$INTERMEDIATE.crt \
      -passin pass:"$PASS"
chmod 444 CA/certs/ca$INTERMEDIATE.crt

openssl x509 -noout -text -in CA/certs/ca$INTERMEDIATE.crt
openssl verify -CAfile CA/certs/ca.crt CA/certs/ca$INTERMEDIATE.crt

cat CA/certs/ca.crt CA/certs/ca$INTERMEDIATE.crt > CA/certs/ca$INTERMEDIATE-chain.crt
chmod 444 CA/certs/ca$INTERMEDIATE-chain.crt

ln -sf ca$INTERMEDIATE-chain.crt CA/certs/ca-chain-int.crt
ln -sf ca$INTERMEDIATE.crt CA/certs/ca-int.crt
ln -sf ca$INTERMEDIATE.key CA/private/ca-int.key

openvpn --genkey --secret tls/private/ta.key
chmod 400 tls/private/ta.key

