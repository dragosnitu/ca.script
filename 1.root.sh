#!/bin/bash

. ./config

cd $ROOT_DIR
mkdir -p CA/{certs,newcerts,crl,private,csr}
chmod 700 CA/private
touch CA/index.txt
echo 1000 > CA/serial
echo 1000 > CA/crlnumber
dd if=/dev/urandom of=$HOME/.rnd bs=1024 count=1

sed "s|TEMPLATE_NAME|$MY_URL|g" templates/openssl.template >openssl.cnf
sed -i "s|TEMPLATE_HOME|$ROOT_DIR/CA|g" openssl.cnf
sed -i "s|TEMPLATE_COMPANY|$COMPANY|g" openssl.cnf
sed -i "s|TEMPLATE_DAYS_ROOT|$DAYS_ROOT|g" openssl.cnf
sed -i "s|TEMPLATE_DAYS_CERT|$DAYS_CERT|g" openssl.cnf
sed -i "s|TEMPLATE_SHA|$SHA|g" openssl.cnf
sed -i "s|TEMPLATE_BITS|$BITS|g" openssl.cnf

openssl genpkey -algorithm RSA -out CA/private/ca.key -pkeyopt rsa_keygen_bits:$BITS -aes-256-cbc -pass pass:"$PASS"
chmod 400 CA/private/ca.key

openssl req -config ./openssl.cnf \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$COMPANY/OU=Networking/CN=$COMPANY Root CA" \
    -key CA/private/ca.key \
    -new -x509 -days $DAYS_ROOT -$SHA -extensions v3_ca \
    -out CA/certs/ca.crt \
    -passin pass:"$PASS"

chmod 444 CA/certs/ca.crt

openssl x509 -noout -text -in CA/certs/ca.crt

