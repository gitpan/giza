#!/bin/bash
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Configure.sh - giza makefile builder.
# (c) 1996-2002 ABC Startsiden AS, see the file AUTHORS.
#
# See the file LICENSE in the Giza top source distribution tree for
# licensing information. If this file is not present you are *not*
# allowed to view, run, copy or change this software or it's sourcecode.
# -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
#####

MODULE_REQUIREMENTS=$(cat PERLREQ);

# ### error(errormessage)
# Print a message to standard error and exit.
#
error()
{
	echo -e "\n$1\n\n" >/dev/stderr
	exit 1
}

# ### getval(keyvalue_pair)
# Get the value part of a key=value pair.
#
getval()
{
	echo $1 | cut -d= -f2
}

# ### show_help()
# Print help screen and exit.
show_help()
{
	cat <<EOF

Help for giza configuration script.
All flags needs an argument in the type of: --argument=value.

--prefix			Installation prefix.
--perl				Path to perl interpreter.
--perlflags			Flags to pass the perl interpreter.
--with-debug		Add debugging code.
--with-selfloader	Use SelfLoader to speed up module loading.
--with-sequences	Use SQL Sequences
--pimpx				Path to PiMPx
--with-webuser		The user the webserver runs as
--with-webgroup		The group the webserver runs as
--with-dbtype			RDBMS type, can be any of the following:
					postgres
					db2
					mysql
					msql
--with-db-user			Username to use for db access.
--with-db-pass			Password for the database user.
--with-db-host			Hostname to the databaseserver.
--with-config-cache-type	Cache type for the configuration, 
				can be any of the following:
					memshare
					storable
					memcopy
				See perldoc XML::Simple for more info.

EOF
	exit 1;
}


# ---------------------------------------------------------------------- #
# The white stuff.

echo "Configure for GIZA2..... ";
echo

# ### read the configuration defaults.
. config.defs

# ### read the cache (if any).
if [ -f "config.cache" ]; then
	. config.cache
fi

# ### parse arguments
for arg in $*
do
	case $arg in
		--prefix=*)
			PREFIX=$(getval $arg)
		;;
		--perl=*)
			PERL=$(getval $arg)
		;;
		--perlflags=*)
			PERLFLAGS=$(getval $arg)
		;;
		--pimpx=*)
			PIMPX=$(getval $arg)
		;;
		--with-dbtype=*)
			DBTYPE=$(getval $arg)
		;;
		--with-db=*)
			DBNAME=$(getval $arg)
		;;
		--with-db-user=*)
			DBUSER=$(getval $arg)
		;;
		--with-db-pass=*)
			DBPASS=$(getval $arg)
		;;
		--with-db-host=*)
			DBHOST=$(getval $arg)
		;;
		--with-webuser=*)
			WEBUSER=$(getval $arg)
		;;
		--with-webgroup=*)
			WEBGROUP=$(getval $arg)
		;;
		--with-config-cache-type=*)
			CONFIG_CACHE_TYPE=$(getval $arg)
		;;
		--with-debug*)
			DEBUG=1
		;;
		--without-debug*)
			DEBUG=0
		;;
		--with-selfloader*)
			SELFLOADER=1
		;;
		--without-selfloader*)
			SELFLOADER=0
		;;
		--with-sequences*)
			SQL_SEQUENCES=1
		;;
		--without-sequences*)
			SQL_SEQUENCES=0
		;;
		--help)
			show_help
		;;
	esac
done

if [ "$DBTYPE" = "postgres" ]; then
	SQL_SEQUENCES=1
fi

echo "Checking perl environment..."
for mod in $MODULE_REQUIREMENTS; do
	echo -n "  $mod....... "
	$PERL -M$mod -e1 || error "Dependency failed: $mod. Please read README"
	echo "ok"
done

$PERL -MTime::HiRes -e1 && HAVE_TIME__HIRES=1

echo

echo "Checking pimpx... "
if [ ! -x "$PIMPX" ]; then
	error "Missing pimpx. Please read README"
fi

echo

echo "Summary:"
echo "  prefix..................$PREFIX"
echo "  perl....................$PERL"
echo "  perlflags...............$PERLFLAGS"
echo "  pimpx...................$PIMPX"
echo "  config cache type.......$CONFIG_CACHE_TYPE"

echo

# ### Write config.cache
echo "Writing cache..."
cat << EOF > config.cache
	PERL=$PERL
	PERLFLAGS=$PERLFLAGS
	PIMPX=$PIMPX
	PREFIX=$PREFIX
	DBTYPE=$DBTYPE
	DBNAME=$DBNAME
	DBUSER=$DBUSER
	DBPASS=$DBPASS
	DBHOST=$DBHOST
	DEBUG=$DEBUG
	CONFIG_CACHE_TYPE=$CONFIG_CACHE_TYPE
	WEBUSER=$WEBUSER
	WEBGROUP=$WEBGROUP
	SELFLOADER=$SELFLOADER
	SQL_SEQUENCES=$SQL_SEQUENCES
	HAVE_TIME__HIRES=$HAVE_TIME__HIRES
EOF

# ### Write config.pimpx
echo "Writing pimpx include file... "
cat << EOF > config.pimpx
	#%define PERL 				"$PERL"
	#%define PERLFLAGS 			"$PERLFLAGS"
	#%define PIMPX 				"$PIMPX"
	#%define PREFIX 			"$PREFIX"
	#%define DBTYPE 			"$DBTYPE"
	#%define DBNAME 			"$DBNAME"
	#%define DBUSER 			"$DBUSER"
	#%define DBPASS 			"$DBPASS"
	#%define DBHOST 			"$DBHOST"
	#%define DEBUG				"$DEBUG"
	#%define CONFIG_CACHE_TYPE	"$CONFIG_CACHE_TYPE"
	#%define WEBUSER			"$WEBUSER"
	#%define WEBGROUP			"$WEBGROUP"
	#%define SELFLOADER			"$SELFLOADER"
	#%define HAVE_TIME__HIRES	"$HAVE_TIME__HIRES"
	#%define SQL_SEQUENCES		"$SQL_SEQUENCES"
EOF

echo "Creating Makefile... "
$PIMPX Makefile.tmpl -OMakefile

echo
echo "Configure now done, type \`make install' to complete installation";
echo "or issue \`make upgrade' if you have an existing installation.";
echo
