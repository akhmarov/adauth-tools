#!/usr/bin/env bash

# ------------------------------------------------------------------------------
#
# Active Directory - Basic Actions Library
#
# Version:  1.0
# Date:     August 2013
# Author:   Vladimir Akhmarov
#
# Description:
#   This script is a collection of functions required for proper join/leave
#   process of the Linux machine to the Active Directory 2003 R2+ domain. This
#   functions includes installation of the necessary packages and work with
#   Kerberos, Samba, SSSD and Sudo config files
#
# ------------------------------------------------------------------------------

LOG_FILE = 'adauth.log'

PKG_UTIL = 'yum -y install'
PKG_DEPS = 'authconfig krb5-workstation oddjob-mkhomedir pam_krb5 samba-common sssd'

KERBEROS_CONFIG = '/etc/krb5.conf'
SAMBA_CONFIG = '/etc/samba/smb.conf'
SSSD_CONFIG = '/etc/sssd/sssd.conf'
SUDO_CONFIG = '/etc/sudoers.d/domain'

BACKUP_POSTFIX = 'adauth'

# ------------------------------------------------------------------------------

#
# Function: libadauth_install_deps
#
# Arguments:
#   $1 -- package util binary
#   $2 -- dependency packages
#
# Returns:
#   bool
#
# Description:
#   Function installs all packages that are needed by linux machine to be
#   properly joined to the Active Directory domain. On success returns 0
#

function libadauth_install_deps
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	$1 $2 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

# ------------------------------------------------------------------------------

#
# Function: libadauth_kerberos_backup
#
# Arguments:
#   $1 -- Kerberos config file path
#   $2 -- backup file postfix
#
# Returns:
#   bool
#
# Description:
#   Function makes a backup copy of Kerberos general config file in the same
#   directory with a selected name postfix. If there is another backup file with
#   the same name it will NOT be rewritten. On success returns 0
#

function libadauth_kerberos_backup
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	no | cp -v $1 $1.$2 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

#
# Function: libadauth_kerberos_restore
#
# Arguments:
#   $1 -- Kerberos config file path
#   $2 -- backup file postfix
#
# Returns:
#   bool
#
# Description:
#   Function restores backup copy of the Kerberos general config file to the
#   current active config file. On success returns 0
#

function libadauth_kerberos_restore
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	mv -fv $1.2 $1 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

#
# Function: libadauth_kerberos_config
#
# Arguments:
#  $1 -- Kerberos config file path
#  $2 -- domain FQDN
#
# Returns:
#   bool
#
# Description:
#   Function configures Kerberos general config with appropriate values. On
#   success returns 0
#

function libadauth_kerberos_config
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	# Convert domain FQDN to uppercase string
	local DOMAIN_FQDN=$(echo $2 | tr '[:lower:]' '[:upper:]')

	authconfig --enablekrb5 --enablekrb5kdcdns --enablekrb5realmdns --krb5realm=$DOMAIN_FQDN --update 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	# Set Active Directory 2003 R2+ compatible crypto algorithms
	sed -e '/\[libdefaults\]/{:a;n;/^$/!ba;i\
 default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac \
 default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac \
 permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac' -e '}' -i $1 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	# Delete example strings from config
	sed -e '/EXAMPLE.COM = {/,/}/d' -e '/example.com/d' -i $1 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

# ------------------------------------------------------------------------------

#
# Function: libadauth_samba_backup
#
# Arguments:
#   $1 -- Samba config file path
#   $2 -- backup file postfix
#
# Returns:
#   bool
#
# Description:
#   Function makes a backup copy of Samba general config file in the same
#   directory with a selected name postfix. If there is another backup file with
#   the same name it will NOT be rewritten. On success returns 0
#

function libadauth_samba_backup
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	no | cp -v $1 $1.$2 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

#
# Function: libadauth_samba_restore
#
# Arguments:
#   $1 -- Samba config file path
#   $2 -- backup file postfix
#
# Returns:
#   bool
#
# Description:
#   Function restores backup copy of the Samba general config file to the
#   current active config file. On success returns 0
#

function libadauth_samba_restore
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	mv -fv $1.2 $1 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

#
# Function: libadauth_samba_config
#
# Arguments:
#   $1 -- Samba config file path
#   $2 -- domain NetBIOS name
#   $3 -- domain FQDN
#
# Returns:
#   bool
#
# Description:
#   Function configures Samba config file with appropriate values. On success
#   returns 0
#

function libadauth_samba_config
{
	if [ $# -ne 3 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ] || [ "x$3" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	# Conver domain NetBIOS name and FQDN to uppercase strings
	local DOMAIN_NBNAME=$(echo $2 | tr '[:lower:]' '[:upper:]')
	local DOMAIN_FQDN=$(echo $3 | tr '[:lower:]' '[:upper:]')

	authconfig --smbsecurity=ads --smbworkgroup=$DOMAIN_NBNAME --smbrealm=$DOMAIN_FQDN --update 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	# Set proper domain connection and search attributes
	sed -e '/security = ads/,/^$/c\
   security = ads \
   client signing = yes \
   client use spnego = yes \
   kerberos method = secrets and keytab \
   password server = * \
' -i $1 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

# ------------------------------------------------------------------------------

#
# Function: libadauth_sssd_backup
#
# Arguments:
#   $1 -- SSSD config file path
#   $2 -- backup file postfix
#
# Returns:
#   bool
#
# Description:
#   Function makes a backup copy of SSSD general config file in the same
#   directory with a selected name postfix. If there is another backup file with
#   the same name it will NOT be rewritten. On success returns 0
#

function libadauth_sssd_backup
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	if [ -f $1 ]; then
		no | cp -v $1 $1.$2 1>$LOG_FILE 2>&1
	fi

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

#
# Function: libadauth_sssd_restore
#
# Arguments:
#   $1 -- SSSD config file path
#   $2 -- backup file postfix
#
# Returns:
#   bool
#
# Description:
#   Function restores backup copy of the SSSD general config file to the current
#   active config file. On success returns 0
#

function libadauth_sssd_restore
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	if [ -f $1.$2 ]; then
		mv -fv $1.2 $1 1>$LOG_FILE 2>&1
	else
		rm -fv $1 1>$LOG_FILE 2>&1
	fi

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

#
# Function: libadauth_sssd_config
#
# Arguments:
#   $1 -- SSSD config file path
#   $2 -- domain FQDN
#   $3 -- LDAP access filter string
#
# Returns:
#   bool
#
# Description:
#   Function configures SSSD config file with appropriate value. On success
#   returns 0
#
# Example: memberOf=CN=Linux Admins,OU=Administrative,OU=Groups,DC=msk,DC=i-teco,DC=ru
#

function libadauth_sssd_config
{
	if [ $# -ne 3 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ] || [ "x$3" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	# Conver domain FQDN to lowercase string
	local DOMAIN_FQDN=$(echo $2 | tr '[:upper:]' '[:lower:]')

	# Get host's Kerberos shortname
	local KERBEROS_SHORTNAME=$(klist -k | tail -n 1 | awk '{print $2}')

	chkconfig messagebus on 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	service messagebus restart 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	authconfig --enablesssdauth --enablesssd --enablelocauthorize --enablemkhomedir --update 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	echo "[sssd]
  config_file_version = 2
  domains = $DOMAIN_FQDN
  services = nss, pam

[nss]
  override_homedir = /home/%d/%u
  override_shell = /bin/bash

[domain/$DOMAIN_FQDN]
  access_provider = ldap
  #access_provider = simple
  auth_provider = ad
  chpass_provider = ad
  id_provider = ad
  ldap_access_order = filter, expire
  ldap_account_expire_policy = ad
  ldap_sasl_mech = GSSAPI
  ldap_sasl_authid = $KERBEROS_SHORTNAME
  ldap_schema = ad
  ldap_referrals = false
  ldap_id_mapping = true
  ldap_force_upper_case_realm = true
  ldap_access_filter = $3
  #simple_allow_groups = Linux Admins
  cache_credentials = false
" >$1 2>$LOG_FILE

	if [ $? -ne 0 ]; then
		return 1
	fi

	chown root:root $1 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	chmod 600 $1 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	chkconfig sssd on 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	service sssd restart 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	service sshd restart 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi
}

# ------------------------------------------------------------------------------

#
# Function: libadauth_sudo_backup
#
# Arguments:
#   $1 -- Sudo config file path
#   $2 -- backup file postfix
#
# Returns:
#   bool
#
# Description:
#   Function makes a backup copy of Sudo general config file in the same
#   directory with a selected name postfix. If there is another backup file with
#   the same name it will NOT be rewritten. On success returns 0
#

function libadauth_sudo_backup
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	if [ -f $1 ]; then
		no | cp -v $1 $1.$2 1>$LOG_FILE 2>&1
	fi

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

#
# Function: libadauth_sudo_restore
#
# Arguments:
#   $1 -- Sudo config file path
#   $2 -- backup file postfix
#
# Returns:
#   bool
#
# Description:
#   Function restores backup copy of the Sudo general config file to the current
#   active config file. On success returns 0
#

function libadauth_sudo_restore
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	if [ -f $1.$2 ]; then
		mv -fv $1.2 $1 1>$LOG_FILE 2>&1
	else
		rm -fv $1 1>$LOG_FILE 2>&1
	fi

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

#
# Function: libadauth_sudo_config
#
# Arguments:
#   $1 -- Sudo config file path
#   $2 -- restricted LDAP groups
#
# Returns:
#   bool
#
# Description:
#   Function write appropriate groups to the sudoers file. On success return 0
#

function libadauth_sudo_config
{
	if [ $# -ne 2 ] || [ "x$1" == 'x' ] || [ "x$2" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	# Temp file for sudoers data
	local SUDOERS_TEMP_FILE = $(mktemp)

	# Prepare restricted groups string for sudoers
	# Split string by commas, remove forwarding and trailing spaces, add prefix (%), protect spaces, build new string
	local LDAP_GROUPS = $(echo $2 |  tr ',' '\n' | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/.*/\%&/' -e 's/ /\\ /' | paste -d ',' | sed 's/,$//')

	echo "
User_Alias LINADMINS = $LDAP_GROUPS
User_Alias WINADMINS = %Domain\ Admins, %Enterprise\ Admins

LINADMINS ALL=(ALL) ALL
WINADMINS ALL=(ALL) ALL
" $SUDOERS_TEMP_FILE 2>$LOG_FILE

	if [ $? -ne 0 ]; then
		return 1
	fi

	chown root:root $SUDOERS_TEMP_FILE 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	chmod 0440 $SUDOERS_TEMP_FILE 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi

	mv $SUDOERS_TEMP_FILE $1 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	fi
}

# ------------------------------------------------------------------------------

#
# Function: libadauth_domain_join
#
# Arguments:
#   $1 -- domain account with domain join rights
#
# Returns:
#   bool
#
# Description:
#   Function initializes Kerberos ticket for user's domain account and after it
#   joins domain. Join process is accompanied with Kerberos ticket creation for
#   machines domain account. So after the process there is a new domain object
#   with proper OS Name and OS Version. On success returns 0
#

function libadauth_domain_join
{
	if [ $# -ne 1 ] || [ "x$1" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	kinit "$1" 2>$LOG_FILE

	if [ $? -ne 0 ]; then
		return 1
	fi

	net ads join osName=$(awk '{print $1}' /etc/system-release) osVersion=$(awk '{print $3}' /etc/system-release) -k 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}

#
# Function: libadauth_domain_leave
#
# Arguments:
#   $1 -- domain account with domain leave rights
#
# Returns:
#   bool
#
# Description:
#   Function leaves domain using selected user account with appropriate rights.
#   Then it destroys all acquired Kerberos tickets. On success returns 0
#

function libadauth_domain_leave
{
	if [ $# -ne 1 ] || [ "x$1" == 'x' ]; then
		echo "ERROR: $FUNCNAME -- Missing arguments" >$LOG_FILE
		return 1
	fi

	net ads leave -U "$1" 2>$LOG_FILE

	if [ $? -ne 0 ]; then
		return 1
	fi

	kdestroy 1>$LOG_FILE 2>&1

	if [ $? -ne 0 ]; then
		return 1
	else
		return 0
	fi
}
