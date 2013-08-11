#!/usr/bin/env bash

# ------------------------------------------------------------------------------
#
# Active Directory - Leave Domain Script
#
# Version:  1.0
# Date:     August 2013
# Author:   Vladimir Akhmarov
#
# Description:
#   This script leaves currently joined domain and restores previous versions of
#   all config files. Machine account that previously was created will be
#   deleted.
#
# ------------------------------------------------------------------------------

function usage
{
    echo -e "\nUsage: adauth-leave.sh -u USERNAME"
    echo -e ''
    echo -e 'Mandatory:'
    echo -e '  -u -- Active Directory user with domain leave rights'
    echo -e ''

    exit 1
}

while getopts ':u:' VAR; do
    case $VAR in
        u)
            DOMAIN_USER=$OPTARG
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

if [ $# -eq 0 ] || [ -z $DOMAIN_USER ]; then
    usage
fi

# ------------------------------------------------------------------------------
. $(dirname $0)/libadauth.sh
# ------------------------------------------------------------------------------

#
# Algorithm (leave domain):
#   1. Leave domain
#   2. Restore config files
#

echo -n 'Leaving Active Directory...'

libadauth_domain_leave $DOMAIN_USER

if [ $? -ne 0 ]; then
	echo ' [FAIL]'
	echo ''
	echo "There was errors during setup process. See $LOG_FILE for details"

	exit 1
fi

echo -n 'Restoring configs...'

RET_KRB = libadauth_restore_kerberos $KERBEROS_CONFIG $BACKUP_POSTFIX
RET_SMB = libadauth_restore_samba $SAMBA_CONFIG $BACKUP_POSTFIX
RET_SSS = libadauth_restore_sssd $SSSD_CONFIG $BACKUP_POSTFIX
RET_SUD = libadauth_restore_sudo $SUDO_CONFIG $BACKUP_POSTFIX

if [ $RET_KRB -eq 0 ] && [ $RET_SMB -eq 0 ] && [ $RET_SSS -eq 0 ] && [ $RET_SUD -eq 0 ]; then
	echo ' [OK]'
else
	echo ' [FAIL]'
	echo ''
	echo "There was errors during setup process. See $LOG_FILE for details"

	exit
fi
