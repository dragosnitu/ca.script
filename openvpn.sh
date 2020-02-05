#!/bin/bash

. ./config
cd $ROOT_DIR

if [ -z "$1" ]; then
    echo -n "Enter email address: "
    read DOMAIN
else
    DOMAIN=$1
fi
echo "$DOMAIN" | grep @ >&/dev/null; TEST=$?
if [ "$TEST" = 0 ]; then
    EXT=usr_cert
fi

echo "$DOMAIN" | grep @ >&/dev/null && EXT=usr_cert || EXT=server_cert
echo "$DOMAIN" | grep @ >&/dev/null && EMAIL=$DOMAIN || EMAIL=noc@$DOMAIN
echo "$DOMAIN" | grep @ >&/dev/null && TEMPLATE=client || TEMPLATE=server

if [ -f tls/private/$DOMAIN.key -a -f tls/certs/$DOMAIN.crt ]; then
    echo "Generating OpenVPN config and $DOMAIN ($EXT)."
else
    echo "Key and certificate for $DOMAIN does not exist. Use ./sign.sh to generate the key&certificate bundle"
    exit
fi

sed "s/TEMPLATE_NAME/$MY_URL/g" templates/$TEMPLATE.template >configs/$DOMAIN.ovpn

echo '<ca>' >>configs/$DOMAIN.ovpn
cat CA/certs/ca.crt >>configs/$DOMAIN.ovpn
echo '</ca>' >>configs/$DOMAIN.ovpn

echo '<cert>' >>configs/$DOMAIN.ovpn
cat tls/certs/$DOMAIN.crt >>configs/$DOMAIN.ovpn
cat CA/certs/ca$INTERMEDIATE-chain.crt >>configs/$DOMAIN.ovpn
echo '</cert>' >>configs/$DOMAIN.ovpn

echo '<key>' >>configs/$DOMAIN.ovpn
cat tls/private/$DOMAIN.key >>configs/$DOMAIN.ovpn
echo '</key>' >>configs/$DOMAIN.ovpn

echo '<tls-auth>' >>configs/$DOMAIN.ovpn
cat tls/private/ta.key >>configs/$DOMAIN.ovpn
echo '</tls-auth>' >>configs/$DOMAIN.ovpn

if [ x"$EXT" == x"server_cert" ]; then
    echo '<dh>' >>configs/$DOMAIN.ovpn
    cat tls/certs/$DOMAIN-dhparam.pem >>configs/$DOMAIN.ovpn
    echo '</dh>' >>configs/$DOMAIN.ovpn
    echo '<crl-verify>' >>configs/$DOMAIN.ovpn
    cat CA/crl/ca.crl >>configs/$DOMAIN.ovpn
    echo '</crl-verify>' >>configs/$DOMAIN.ovpn
fi
