#!/bin/sh

set -e

DOMAIN=${DOMAIN:-domain.tld}
DOMAIN_SUFFIX="dc=`echo $DOMAIN | sed -e 's/\./,dc=/g'`"

if ! slapcat > /dev/null 2>&1; then
	ADMIN_CN=${ADMIN_CN:-Manager}
	ROOT_DN="cn=$ADMIN_CN,$DOMAIN_SUFFIX"
	PASSWORD_HASH=${PASSWORD_HASH:-'{CRYPT}'}
	PASSWORD_CRYPT_SALT_FORMAT=${PASSWORD_CRYPT_SALT_FORMAT:-'"$1$%.8s"'}

	cat /dev/null > /etc/openldap/slapd.conf
	for s in ${SCHEMAS:-core}; do
		echo "include /etc/openldap/schema/$s.schema" >> /etc/openldap/slapd.conf
	done

	cat << EOF >> /etc/openldap/slapd.conf
pidfile /var/run/openldap/slapd.pid
argsfile /var/run/openldap/slapd.args
database mdb
maxsize ${MAX_SIZE:-1073741824}
suffix "$DOMAIN_SUFFIX"
rootdn "$ROOT_DN"
rootpw $ADMIN_PW
directory ${LDAP_DIRECTORY:-/var/lib/openldap/openldap-data}
index objectClass eq
password-hash $PASSWORD_HASH
password-crypt-salt-format $PASSWORD_CRYPT_SALT_FORMAT
${TLS_CA_CERTIFICATE_FILE:+"TLSCACertificateFile $TLS_CA_CERTIFICATE_FILE"}
${TLS_CERTIFICATE_FILE:+"TLSCertificateFile $TLS_CERTIFICATE_FILE"}
${TLS_CERTIFICATE_KEY_FILE:+"TLSCertificateKeyFile $TLS_CERTIFICATE_KEY_FILE"}
$ACL
EOF

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
