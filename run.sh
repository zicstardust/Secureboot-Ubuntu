export KEYS_DIR="/etc/secureboot-keys"
export MOKCONFIG="mokconfig.cnf"
export KEY_NAME="MOKKERNEL"
export CONTROL="${KEYS_DIR}/continue"
sudo su

if [ -f "$CONTROL" ]; then
cat > /etc/kernel/postinst.d/00-signing <<HOOK
#!/bin/usr/env bash

set -e

KERNEL_IMAGE="\$2"
MOK_CERT_NAME="${KEY_NAME}"
MOK_DIRECTORY="${KEYS_DIR}"

if [ "$#" -ne "2" ] ; then
	echo "Wrong count of command line arguments. This is not meant to be called directly." >&2
	exit 1
fi

if [ ! -x "$(command -v sbsign)" ] ; then
	echo "sbsign not executable. Bailing." >&2
	exit 1
fi

if [ ! -r "\$MOK_DIRECTORY/\$MOK_CERT_NAME.der" ] ; then
	echo "\$MOK_DIRECTORY/\$MOK_CERT_NAME.der is not readable." >&2
	exit 1
fi

if [ ! -r "\$MOK_DIRECTORY/\$MOK_CERT_NAME.priv" ] ; then
	echo "\$MOK_DIRECTORY/\$MOK_CERT_NAME.priv is not readable." >&2
	exit 1
fi

if [ ! -w "\$KERNEL_IMAGE" ] ; then
	echo "Kernel image \$KERNEL_IMAGE is not writable." >&2
	exit 1
fi

if [ ! -r "\$MOK_DIRECTORY/\$MOK_CERT_NAME.pem" ] ; then
	echo "\$MOK_CERT_NAME.pem missing. Generating from \$MOK_CERT_NAME.der."
	if [ ! -x "$(command -v openssl)" ] ; then
		echo "openssl could not be found. Bailing." >&2
		exit 1
	fi
	openssl x509 -in "\$MOK_DIRECTORY/\$MOK_CERT_NAME.der" -inform DER -outform PEM -out "\$MOK_DIRECTORY/\$MOK_CERT_NAME.pem" || { echo "Conversion failed. Bailing." >&2; exit 1 ; }
fi

echo "Signing \$KERNEL_IMAGE..."
sbsign --key "\$MOK_DIRECTORY/\$MOK_CERT_NAME.priv" --cert "\$MOK_DIRECTORY/\$MOK_CERT_NAME.pem" --output "\$KERNEL_IMAGE" "\$KERNEL_IMAGE"
HOOK
	chown root:root /etc/kernel/postinst.d/00-signing
	chmod u+rx /etc/kernel/postinst.d/00-signing
	rm -f ${CONTROL}
else
	mkdir -p ${KEYS_DIR}
	cat > ${KEYS_DIR}/${MOKCONFIG} <<KEYS
	# This definition stops the following lines failing if HOME isn't
	# defined.
	HOME                    = .
	RANDFILE                = \$ENV::HOME/.rnd
	[ req ]
	distinguished_name      = req_distinguished_name
	x509_extensions         = v3
	string_mask             = utf8only
	prompt                  = no
	" >> mokconfig.cnf
	[ req_distinguished_name ]
	countryName             = BR
	stateOrProvinceName     = Nada
	localityName            = Nada
	0.organizationName      = nenhuma
	commonName              = Secure Boot Signing Key
	emailAddress            = nada@nenhuma.com
	
	[ v3 ]
	subjectKeyIdentifier    = hash
	authorityKeyIdentifier  = keyid:always,issuer
	basicConstraints        = critical,CA:FALSE
	extendedKeyUsage        = codeSigning,1.3.6.1.4.1.311.10.3.6
	nsComment               = "OpenSSL Generated Certificate"
KEYS
	chmod +x ${KEYS_DIR}/${MOKCONFIG}
	openssl req -config ${KEYS_DIR}/${MOKCONFIG} -new -x509 -newkey rsa:2048 -nodes -days 36500 -outform DER -keyout "${KEYS_DIR}/${KEY_NAME}.priv" -out "${KEYS_DIR}/${KEY_NAME}.der"
	openssl x509 -in ${KEYS_DIR}/${KEY_NAME}.der -inform DER -outform PEM -out ${KEYS_DIR}/${KEY_NAME}.pem
	mokutil --import ${KEYS_DIR}/${KEY_NAME}.der   
	echo "Run script again after reboot"
	touch ${CONTROL}
	sleep 5
	reboot
fi




