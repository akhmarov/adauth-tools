#!/usr/bin/env bash

# ------------------------------------------------------------------------------
#
# Active Directory - Join Domain Script
#
# Version:  1.0
# Date:     August 2013
# Author:   Vladimir Akhmarov
#
# Description:
#   This script make changes to the Kerberos/Samba/SSSD/Sudo configuration files
#   and joins Active Directory 2003 R2+ domain. New domain machine account with
#   filled in OS Name and OS Version fields is created also.
#
# ------------------------------------------------------------------------------

function usage
{
    echo -e "\nUsage: adauth-join.sh -d FQDN -n NBNAME -u USERNAME [-f LDAP_FILTER] [-g LDAP_GROUPS]"
    echo -e ''
    echo -e 'Mandatory:'
    echo -e '  -d -- Active Directory fully qualified domain name (FQDN)'
    echo -e '  -n -- Active Directory NetBIOS name'
    echo -e '  -u -- Active Directory user with domain join rights'
    echo -e 'Optional:'
    echo -e '  -f -- LDAP filter string'
    echo -e '  -g -- LDAP restricted logon groups'
    echo -e ''

    exit 1
}

while getopts ':d:n:u:f:g:' VAR; do
    case $VAR in
        d)
            DOMAIN_FQDN=$OPTARG
            ;;
        n)
            DOMAIN_NBNAME=$OPTARG
            ;;
        u)
            DOMAIN_USER=$OPTARG
            ;;
        f)
            LDAP_FILTER=$OPTARG
            ;;
        g)
            LDAP_GROUPS=$OPTARG
            ;;
        :)
            echo "ERROR: Option -$OPTARG requires an argument" >&2
            usage
            ;;
        \?)
            echo "ERROR: Invalid option -$OPTARG" >&2
            usage
            ;;
    esac
done

if [ $# -eq 0 ] || [ -z $DOMAIN_FQDN ] || [ -z $DOMAIN_NBNAME ] || [ -z $DOMAIN_USER ]; then
    usage
fi

# ------------------------------------------------------------------------------
. $(dirname $0)/libadauth.sh
# ------------------------------------------------------------------------------

#
# Algorithm (join domain):
#   1. Install dependencies
#   2. Backup config files
#   3. Configure Kerberos
#   4. Configure Samba
#   5. Join domain
#   6. Configure SSSD
#   7. Configure Sudo
#

echo -n 'Installing packages...'

libadauth_install_deps $PKG_UTIL $PKG_DEPS

if [ $? -eq 0 ]; then
	echo ' [OK]'
else
	echo ' [FAIL]'
	echo ''
	echo "There was errors during setup process. See $LOG_FILE for details"

	exit 1
fi

echo -n 'Backing up configs...'

RET_KRB = libadauth_backup_kerberos $KERBEROS_CONFIG $BACKUP_POSTFIX
RET_SMB = libadauth_backup_samba $SAMBA_CONFIG $BACKUP_POSTFIX
RET_SSS = libadauth_backup_sssd $SSSD_CONFIG $BACKUP_POSTFIX
RET_SUD = libadauth_backup_sudo $SUDO_CONFIG $BACKUP_POSTFIX

if [ $RET_KRB -eq 0 ] && [ $RET_SMB -eq 0 ] && [ $RET_SSS -eq 0 ] && [ $RET_SUD -eq 0 ]; then
	echo ' [OK]'
else
	echo ' [FAIL]'
	echo ''
	echo "There was errors during setup process. See $LOG_FILE for details"

	exit
fi

echo -n 'Configuring Kerberos/Samba...'

RET_KRB = libadauth_config_kerberos $KERBEROS_CONFIG $DOMAIN_FQDN
RET_SMB = libadauth_config_samba $SAMBA_CONFIG $DOMAIN_NBNAME $DOMAIN_FQDN

if [ $RET_KRB -eq 0 ] && [ $RET_SMB -eq 0 ]; then
	echo ' [OK]'
else
	echo ' [FAIL]'
	echo ''
	echo "There was errors during setup process. See $LOG_FILE for details"

	exit
fi

echo -n 'Joining Active Directory...'

libadauth_domain_join $DOMAIN_USER

if [ $? -ne 0 ]; then
	echo ' [FAIL]'
	echo ''
	echo "There was errors during setup process. See $LOG_FILE for details"

	exit 1
fi

echo -n 'Configuring SSSD/Sudo...'

RET_SSS = libadauth_config_sssd $SSSD_CONFIG $DOMAIN_FQDN $LDAP_FILTER
RET_SUD = libadauth_config_sudo $SUDO_CONFIG $LDAP_GROUPS

if [ $RET_SSS -eq 0 ] && [ $RET_SUD -eq 0 ]; then
	echo ' [OK]'
else
	echo ' [FAIL]'
	echo ''
	echo "There was errors during setup process. See $LOG_FILE for details"

	exit
fi
