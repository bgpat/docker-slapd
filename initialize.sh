#!/bin/sh

DOMAIN=${DOMAIN:-domain.tld}
DOMAIN_SUFFIX="dc=`echo $DOMAIN | sed -e 's/\./,dc=/g'`"
ROOT_DC=`echo $DOMAIN | sed -e 's/\..*$//'`
ADMIN_CN=${ADMIN:-Manager}

ldapadd -x -H ldap://localhost:389 -D "cn=Manager,$DOMAIN_SUFFIX" -w $PASSWORD << EOF
dn: $DOMAIN_SUFFIX
objectClass: dcObject
objectClass: organization
dc: $ROOT_DC
o: $DOMAIN

dn: cn=$ADMIN_CN,$DOMAIN_SUFFIX
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: $ADMIN_CN
description: LDAP administrator
userPassword: $PASSWORD

$INITIALIZE_LDIF
EOF
