export KEYS_DIR="/etc/secureboot-keys"
export MOKCONFIG="mokconfig.cnf"
export KEY_NAME="MOKKERNEL"
export CONTROL="${KEYS_DIR}/contunue"
sudo su

if [ -f "$CONTROL" ]; then
	echo '#!/bin/sh' >> /etc/kernel/postinst.d/00-signing
	echo "" >> /etc/kernel/postinst.d/00-signing
	echo "set -e" >> /etc/kernel/postinst.d/00-signing
	echo "" >> /etc/kernel/postinst.d/00-signing
	echo "KERNEL_IMAGE=\"\$2\"" >> /etc/kernel/postinst.d/00-signing
	echo "MOK_CERT_NAME=\"${KEY_NAME}\"" >> /etc/kernel/postinst.d/00-signing
	echo "MOK_DIRECTORY=\"${KEYS_DIR}\"" >> /etc/kernel/postinst.d/00-signing
	echo "" >> /etc/kernel/postinst.d/00-signing
	echo "if [ \"\$#\" -ne \"2\" ] ; then" >> /etc/kernel/postinst.d/00-signing
	echo "	echo \"Wrong count of command line arguments. This is not meant to be called directly.\" >&2" >> /etc/kernel/postinst.d/00-signing
	echo "	exit 1" >> /etc/kernel/postinst.d/00-signing
	echo "fi" >> /etc/kernel/postinst.d/00-signing
	echo "" >> /etc/kernel/postinst.d/00-signing
	echo "if [ ! -x \"\$(command -v sbsign)\" ] ; then" >> /etc/kernel/postinst.d/00-signing
	echo "	echo \"sbsign not executable. Bailing.\" >&2" >> /etc/kernel/postinst.d/00-signing
	echo "	exit 1" >> /etc/kernel/postinst.d/00-signing
	echo "fi" >> /etc/kernel/postinst.d/00-signing
	echo "" >> /etc/kernel/postinst.d/00-signing
	echo "if [ ! -r \"\$MOK_DIRECTORY/\$MOK_CERT_NAME.der\" ] ; then" >> /etc/kernel/postinst.d/00-signing
	echo "	echo \"\$MOK_DIRECTORY/\$MOK_CERT_NAME.der is not readable.\" >&2" >> /etc/kernel/postinst.d/00-signing
	echo "	exit 1" >> /etc/kernel/postinst.d/00-signing
	echo "fi" >> /etc/kernel/postinst.d/00-signing
	echo "" >> /etc/kernel/postinst.d/00-signing
	echo "if [ ! -r \"\$MOK_DIRECTORY/\$MOK_CERT_NAME.priv\" ] ; then" >> /etc/kernel/postinst.d/00-signing
	echo "	echo \"\$MOK_DIRECTORY/\$MOK_CERT_NAME.priv is not readable.\" >&2" >> /etc/kernel/postinst.d/00-signing
	echo "	exit 1" >> /etc/kernel/postinst.d/00-signing
	echo "fi" >> /etc/kernel/postinst.d/00-signing
	echo "" >> /etc/kernel/postinst.d/00-signing
	echo "if [ ! -w \"\$KERNEL_IMAGE\" ] ; then" >> /etc/kernel/postinst.d/00-signing
	echo "	echo \"Kernel image \$KERNEL_IMAGE is not writable.\" >&2" >> /etc/kernel/postinst.d/00-signing
	echo "	exit 1" >> /etc/kernel/postinst.d/00-signing
	echo "fi" >> /etc/kernel/postinst.d/00-signing
	echo "" >> /etc/kernel/postinst.d/00-signing
	echo "if [ ! -r \"\$MOK_DIRECTORY/\$MOK_CERT_NAME.pem\" ] ; then" >> /etc/kernel/postinst.d/00-signing
	echo "	echo \"\$MOK_CERT_NAME.pem missing. Generating from \$MOK_CERT_NAME.der.\"" >> /etc/kernel/postinst.d/00-signing
	echo "	if [ ! -x \"\$(command -v openssl)\" ] ; then" >> /etc/kernel/postinst.d/00-signing
	echo "		echo \"openssl could not be found. Bailing.\" >&2" >> /etc/kernel/postinst.d/00-signing
	echo "		exit 1" >> /etc/kernel/postinst.d/00-signing
	echo "	fi" >> /etc/kernel/postinst.d/00-signing
	echo "	openssl x509 -in \"\$MOK_DIRECTORY/\$MOK_CERT_NAME.der\" -inform DER -outform PEM -out \"\$MOK_DIRECTORY/\$MOK_CERT_NAME.pem\" || { echo \"Conversion failed. Bailing.\" >&2; exit 1 ; }" >> /etc/kernel/postinst.d/00-signing
	echo "fi" >> /etc/kernel/postinst.d/00-signing
	echo "" >> /etc/kernel/postinst.d/00-signing
	echo "echo \"Signing \$KERNEL_IMAGE...\"" >> /etc/kernel/postinst.d/00-signing
	echo "sbsign --key \"$MOK_DIRECTORY/\$MOK_CERT_NAME.priv\" --cert \"\$MOK_DIRECTORY/\$MOK_CERT_NAME.pem\" --output \"\$KERNEL_IMAGE\" \"\$KERNEL_IMAGE\"" >> /etc/kernel/postinst.d/00-signing
	chown root:root /etc/kernel/postinst.d/00-signing
	chmod u+rx /etc/kernel/postinst.d/00-signing
else
	mkdir ${KEYS_DIR}
	echo "# This definition stops the following lines failing if HOME isn't" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "# defined." >> ${KEYS_DIR}/${MOKCONFIG}
	echo "HOME                    = ." >> ${KEYS_DIR}/${MOKCONFIG}
	echo "RANDFILE                = $ENV::HOME/.rnd" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "[ req ]" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "distinguished_name      = req_distinguished_name" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "x509_extensions         = v3" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "string_mask             = utf8only" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "prompt                  = no" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "" >> mokconfig.cnf
	echo "[ req_distinguished_name ]" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "countryName             = BR" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "stateOrProvinceName     = Nada" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "localityName            = Nada" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "0.organizationName      = nenhuma" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "commonName              = Secure Boot Signing Key" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "emailAddress            = nada@nenhuma.com" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "[ v3 ]" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "subjectKeyIdentifier    = hash" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "authorityKeyIdentifier  = keyid:always,issuer" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "basicConstraints        = critical,CA:FALSE" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "extendedKeyUsage        = codeSigning,1.3.6.1.4.1.311.10.3.6" >> ${KEYS_DIR}/${MOKCONFIG}
	echo "nsComment               = \"OpenSSL Generated Certificate\"" >> ${KEYS_DIR}/${MOKCONFIG}
	chmod +x ${KEYS_DIR}/${MOKCONFIG}
	openssl req -config ${KEYS_DIR}/${MOKCONFIG} -new -x509 -newkey rsa:2048 -nodes -days 36500 -outform DER -keyout "${KEYS_DIR}/${KEY_NAME}.priv" -out "${KEYS_DIR}/${KEY_NAME}.der"
	openssl x509 -in ${KEYS_DIR}/${KEY_NAME}.der -inform DER -outform PEM -out ${KEYS_DIR}/${KEY_NAME}.pem
	mokutil --import ${KEYS_DIR}/${KEY_NAME}.der   
	echo "Continue o script apos a maquina reiniciar"
	touch  ${CONTROL}
	sleep 5
	reboot
fi




