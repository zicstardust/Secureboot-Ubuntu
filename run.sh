#!/usb/bin/env bash
MOK_DIRECTORY="/etc/secureboot-keys"
MOKCONFIG="mokconfig.cnf"
MOK_CERT_NAME="secureboot"

is_root=$(whoami)
if [ ${is_root} != "root" ]; then
	echo "run as root"
	exit 2
fi

mkdir -p ${MOK_DIRECTORY}
cat > ${MOK_DIRECTORY}/${MOKCONFIG} <<MOKCONF
# This definition stops the following lines failing if HOME isn't
# defined.
HOME                    = .
RANDFILE                = \$ENV::HOME/.rnd
[ req ]
distinguished_name      = req_distinguished_name
x509_extensions         = v3
string_mask             = utf8only
prompt                  = no

[ req_distinguished_name ]
countryName             = US
stateOrProvinceName     = nothing
localityName            = nothing
0.organizationName      = nothing
commonName              = Secure Boot Signing Key
emailAddress            = nothing@nothing.com

[ v3 ]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer
basicConstraints        = critical,CA:FALSE
extendedKeyUsage        = codeSigning,1.3.6.1.4.1.311.10.3.6
nsComment               = "OpenSSL Generated Certificate"
MOKCONF

cat > /etc/kernel/postinst.d/00-signing <<HOOK
#!/bin/usr/env bash

set -e

KERNEL_IMAGE="\$2"
MOK_CERT_NAME="${MOK_CERT_NAME}"
MOK_DIRECTORY="${MOK_DIRECTORY}"

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
chmod +x ${MOK_DIRECTORY}/${MOKCONFIG}

openssl req -config ${MOK_DIRECTORY}/${MOKCONFIG} -new -x509 -newkey rsa:2048 -nodes -days 36500 -outform DER -keyout "${MOK_DIRECTORY}/${MOK_CERT_NAME}.priv" -out "${MOK_DIRECTORY}/${MOK_CERT_NAME}.der"
openssl x509 -in ${MOK_DIRECTORY}/${MOK_CERT_NAME}.der -inform DER -outform PEM -out ${MOK_DIRECTORY}/${MOK_CERT_NAME}.pem
mokutil --import ${MOK_DIRECTORY}/${MOK_CERT_NAME}.der   

echo "Reboot in 10 seconds"
sleep 10s
reboot
