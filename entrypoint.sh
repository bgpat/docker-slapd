#!/bin/sh

set -e

DOMAIN=${DOMAIN:-domain.tld}
DOMAIN_SUFFIX="dc=`echo $DOMAIN | sed -e 's/\./,dc=/g'`"

ADMIN_CN=${ADMIN_CN:-Manager}
ROOT_DN="cn=$ADMIN_CN,$DOMAIN_SUFFIX"
PASSWORD_HASH=${PASSWORD_HASH:-'{CRYPT}'}
PASSWORD_CRYPT_SALT_FORMAT=${PASSWORD_CRYPT_SALT_FORMAT:-'"$1$%.8s"'}

cat /dev/null > /etc/openldap/slapd.conf.new
for s in ${SCHEMAS:-core}; do
	f="include /etc/openldap/schema/$s.schema"
	echo $f >> /etc/openldap/slapd.conf.new
	if ! [ -e $f ]; then
		touch $f
	fi
done

for f in $(find /usr/lib/openldap -name '*.so'); do
	echo "moduleload $f" >> /etc/openldap/slapd.conf.new
done

cat << EOF >> /etc/openldap/slapd.conf.new
database $BACKEND
${MAX_SIZE:+"maxsize $MAX_SIZE"}
suffix "$DOMAIN_SUFFIX"
rootdn "$ROOT_DN"
rootpw $ADMIN_PW
directory ${LDAP_DIRECTORY:-/var/lib/openldap/openldap-data}
password-hash $PASSWORD_HASH
password-crypt-salt-format $PASSWORD_CRYPT_SALT_FORMAT
${TLS_CA_CERTIFICATE_FILE:+"TLSCACertificateFile $TLS_CA_CERTIFICATE_FILE"}
${TLS_CERTIFICATE_FILE:+"TLSCertificateFile $TLS_CERTIFICATE_FILE"}
${TLS_CERTIFICATE_KEY_FILE:+"TLSCertificateKeyFile $TLS_CERTIFICATE_KEY_FILE"}
$ACL
EOF

if ! slapcat -c /etc/openldap/slapd.conf.new > /dev/null 2>&1; then
	mv /etc/openldap/slapd.conf.new /etc/openldap/slapd.conf

	cat << EOF > /etc/openldap/schema/custom.schema
$CUSTOM_SCHEMA
EOF

	cat << EOF > /etc/openldap/initial.ldif
dn: $DOMAIN_SUFFIX
objectClass: dcObject
objectClass: organization
dc: `echo $DOMAIN | sed -e 's/\..*$//'`
o: $DOMAIN

dn: $ROOT_DN
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: $ADMIN_CN
description: LDAP administrator
userPassword: $ADMIN_PW

$INITIAL_LDIF
EOF

	echo 'initialize DB'
	slapadd -l /etc/openldap/initial.ldif
fi

set -x
/usr/sbin/slapd -d ${LOG_LEVEL:-256} -h 'ldap:/// ldaps:///'
