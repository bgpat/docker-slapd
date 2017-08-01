#!/bin/sh

LOG_LEVEL=${LOG_LEVEL:-256}
DOMAIN=${DOMAIN:-domain.tld}
DOMAIN_SUFFIX="dc=`echo $DOMAIN | sed -e 's/\./,dc=/g'`"
INCLUDES=${INCLUDES:-core}

cat /dev/null > /etc/openldap/slapd.conf
for s in $INCLUDES; do
	echo "include /etc/openldap/schema/$s.schema" >> /etc/openldap/slapd.conf
done

cat << EOF >> /etc/openldap/slapd.conf
pidfile /var/run/openldap/slapd.pid
argsfile /var/run/openldap/slapd.args
database mdb
maxsize 1073741824
suffix "$DOMAIN_SUFFIX"
rootdn "cn=Manager,$DOMAIN_SUFFIX"
rootpw $PASSWORD
directory /var/lib/openldap/openldap-data
index objectClass eq
EOF

cat << EOF > /etc/openldap/slapd.ldif
dn: cn=config
objectClass: olcGlobal
cn: config
olcArgsFile: /var/lib/openldap/run/slapd.args
olcPidFile: /var/lib/openldap/run/slapd.pid
olcModuleload: back_bdb.la

dn: cn=schema,cn=config
objectClass: olcSchemaConfig
cn: schema
include: file:///etc/openldap/schema/core.ldif

dn: olcDatabase=frontend,cn=config
objectClass: olcDatabaseConfig
objectClass: olcFrontendConfig
olcDatabase: frontend

dn: olcDatabase=mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcSuffix: $DOMAIN_SUFFIX
olcRootDN: cn=Manager,$DOMAIN_SUFFIX
olcRootPW: $PASSWORD
olcDbDirectory:	/var/lib/openldap/openldap-data
olcDbIndex: objectClass eq
EOF

(
while [ -f /initialize.sh ]; do
	sleep 1
	if /initialize.sh; then
		rm /initialize.sh
		break
	fi
done
) &

/usr/sbin/slapd -d $LOG_LEVEL
