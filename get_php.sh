#!/bin/bash

# check for correct interpreter
if [ `echo -n | grep -c -- -n` -gt 0 ]; then
	if [ `bash -c 'echo -n | grep -c -- -n'` -gt 0 ]; then
		echo "Can't do anything for you with this bash! :("
		exit 1
	fi
	exec bash "$0" "$@"
fi

OPTS="$@"
SCRIPT_VERSION="1.85"

SCRIPT_FORCE_REINSTALL=0
SCRIPT_FORCE_UPDATE=0

while [ x"$1" != x ]; do
	OPT=$1
	shift
	case "$OPT" in
		-f)
			SCRIPT_FORCE_REINSTALL=1
			;;
		-u)
			SCRIPT_FORCE_UPDATE=1
			;;
		-h)
			echo "Usage: $0 [-f] [-u]"
			exit
			;;
	esac
done

if [ x"$SCRIPT_FORCE_UPDATE" = x1 ]; then
	echo "Updating get_php.sh, please wait..."
	curl -s "https://raw.githubusercontent.com/MagicalTux/automation/master/get_php.sh" >get_php.sh~
	if [ "$?" != "0" ]; then
		echo "An error occured while downloading the new get_php.sh. Aborting update..."
		exit
	fi
	mv -f get_php.sh~ get_php.sh; chmod 0755 get_php.sh
	exit
fi
# Do we have last version?
echo -n "Checking for last version of get_php.sh..."
LAST_VERSION=`curl -s "https://raw.githubusercontent.com/MagicalTux/automation/master/versions.txt" | grep "^get_php.sh" | awk '{ print $2 }'`
if [ x"$LAST_VERSION" != x"$SCRIPT_VERSION" ]; then
	echo "new version available"
	echo "Updating get_php.sh, please wait..."
	curl -s "https://raw.githubusercontent.com/MagicalTux/automation/master/get_php.sh" >get_php.sh~
	if [ "$?" != "0" ]; then
		echo "An error occured while downloading the new get_php.sh. Aborting update..."
	else
		# We'll do everything in only one line, seems that sh has problems with updates in other cases...
		mv -f get_php.sh~ get_php.sh; chmod 0755 get_php.sh; exec ./get_php.sh "$OPTS"; exit
	fi
else
	echo
fi

if [ x"${APACHE_PREFIX}" = x ]; then
	APACHE_PREFIX="/usr/local/httpd"
fi

if [ ! -d "$APACHE_PREFIX" ]; then
	APACHE_PREFIX=none
	echo "Not using Apache"
else
	echo "Using Apache in ${APACHE_PREFIX}"
fi

if [ x"${PHP_PREFIX}" = x ]; then
	PHP_PREFIX="/usr/local"
fi

# Detect if we're on a debian machine

case `uname` in
	*BSD)
		MD5=md5
		SED=gsed
		MAKE_PROCESSES=$[ `sysctl -n hw.ncpu` * 2 - 1 ]
		DEFAULT_PATH=/usr
		;;
	Darwin)
		MD5=md5
		SED=gsed
		MAKE_PROCESSES=$[ `sysctl -n hw.ncpu` * 2 - 1 ]
		DEFAULT_PATH=/opt/local
		;;
	*)
		MD5=md5sum
		SED=sed
		MAKE_PROCESSES=$[ `grep -c '^processor' /proc/cpuinfo` * 2 - 1 ]
		DEFAULT_PATH=/usr
		;;
esac

PHP_BRANCH="8"

# allow override of php branch easily (TODO: make this a ini file one day)
if [ -f php_branch.txt ]; then
	PHP_BRANCH=`cat php_branch.txt`
fi

if [ x"$PHP_PECL" = x ]; then
	# default set of PECL modules
	PHP_PECL="https://github.com/Imagick/imagick.git uuid https://github.com/php/pecl-mail-mailparse.git apcu"
fi
# PECL DEPENCIES
# imagick : libmagick6-dev

echo -n "Checking for current version of PHP: "
PHP_BINARY="${PHP_PREFIX}/bin/php"
if [ -x "$PHP_BINARY" ]; then
	PHP_CUR_VERSION=`"$PHP_BINARY" -v | head -n 1 | $SED -e 's/^[^ ]* //;s/ .*$//'`
else
	PHP_CUR_VERSION="none"
fi
echo "$PHP_CUR_VERSION"

echo -n "Checking for last version of PHP $PHP_BRANCH: "
PHP_VERSION=`curl -s https://www.php.net/downloads.php | grep "PHP $PHP_BRANCH\." | grep -v logo | head -n 1 | $SED -r -e 's/^.*PHP +//;s/<.*>//;s/ +//g;s/\(.*\)//'`
echo "$PHP_VERSION"

if [ x"$PHP_CUR_VERSION" = x"$PHP_VERSION" ]; then
	if [ x"$SCRIPT_FORCE_REINSTALL" = x1 ]; then
		echo "Update of PHP forced with option -f"
	else
		echo "No update needed"
		exit
	fi
fi

PHP_FILE="php-$PHP_VERSION.tar.bz2"
PHP_DIR="php-web-$PHP_VERSION"


if [ ! -f "$PHP_FILE" ]; then
	echo -n "Downloading PHP $PHP_VERSION..."
	# from/this/mirror allows autodetection to give us closest mirror
	wget --timeout=300 -q -O "$PHP_FILE" "http://php.net/get/$PHP_FILE/from/this/mirror"

	if [ $? != "0" ]; then
		echo "Could not download $PHP_FILE"
		rm -f "$PHP_FILE"
		exit 1
	fi
	echo "done"
fi

IS_CLEAN=no
if [ ! -d "$PHP_DIR" ]; then
	echo -n "Extracting PHP... "
	IS_CLEAN=yes
	tar xjf "$PHP_FILE"
	if [ $? != "0" ]; then
		echo "failed"
		exit 1
	fi
	mv "php-$PHP_VERSION" "$PHP_DIR"
	echo "done"
	cd "$PHP_DIR"
else
	cd "$PHP_DIR"
fi

if [ x"$IS_CLEAN" != x"yes" ]; then
	echo -n "Cleaning..."
	make clean >/dev/null 2>&1
	echo
fi

CONFIGURE=()

if [ x"$APACHE_PREFIX" = x"none" ]; then
	CONFIGURE+=("--enable-fpm")
else
	CONFIGURE+=("--with-apxs2=${APACHE_PREFIX}/bin/apxs")
fi

CONFIGURE+=("--prefix=${PHP_PREFIX}" "--enable-inline-optimization")

# encoding stuff
CONFIGURE+=("--with-iconv" "--with-iconv-dir" "--enable-mbstring")
# libintl (ICU)
CONFIGURE+=("--enable-intl" "--with-icu-dir=$DEFAULT_PATH")
# features
CONFIGURE+=("--enable-calendar" "--enable-exif" "--enable-pcntl" "--enable-bcmath" "--with-gettext" "--with-password-argon2=$DEFAULT_PATH")
# compression
CONFIGURE+=("--with-zlib" "--with-zlib-dir=$DEFAULT_PATH" "--with-bz2" "--with-zip")
# MySQL
CONFIGURE+=("--with-mysqli=mysqlnd" "--with-mysql=mysqlnd" "--with-pdo-mysql=mysqlnd")
# GD
CONFIGURE+=("--enable-gd" "--enable-gd-native-ttf" "--with-jpeg-dir=$DEFAULT_PATH" "--with-png-dir=$DEFAULT_PATH" "--with-freetype-dir=$DEFAULT_PATH")
# XML
CONFIGURE+=("--enable-wddx" "--with-xmlrpc" "--with-xsl" "--with-tidy" "--enable-soap")
# OpenSSL
CONFIGURE+=("--with-openssl" "--with-mhash" "--with-gmp=$DEFAULT_PATH" "--with-sodium")
# Network
CONFIGURE+=("--enable-sockets" "--enable-ftp" "--with-curl=$DEFAULT_PATH" "--with-imap" "--with-imap-ssl")
# Basic stuff
CONFIGURE+=("--with-config-file-path=${PHP_PREFIX}/lib/php-web" "--disable-cgi")

# detect freetds and use
if [ -f /usr/lib64/libsybdb.so ]; then
	echo "Found MSSQL library, using it"
	CONFIGURE+=("--with-mssql=/usr")
fi

if [ `ldd /usr/lib/libc-client.so | grep -c libgssapi` -gt 0 ]; then
	# libc-client uses krb, need to enable it
	CONFIGURE+=("--with-kerberos")
fi

echo -n "Configure... ";

# force linking of libstdc++ by default since it is required but PHP doesn't handle it right
LIBS="-lstdc++" ./configure >configure.log 2>&1 "${CONFIGURE[@]}"

if [ x"$?" != x"0" ]; then
	echo "FAILED"
	tail configure.log
	exit 1
fi

echo ""
echo -n "Compiling..."
make -j"$MAKE_PROCESSES" >make.log 2>&1

if [ x"$?" != x"0" ]; then
	echo "FAILED"
	tail make.log
	exit 1
fi

echo ""
echo -n "Installing..."
if [ ! -d "${PHP_PREFIX}/lib/php-web" ]; then
	mkdir -p "${PHP_PREFIX}/lib/php-web"
	cp "${PHP_PREFIX}/lib/php.ini" "${PHP_PREFIX}/lib/php-web/php.ini"
fi

# if using apache, we need to run that now to limit downtime
if [ x"$APACHE_PREFIX" = x"none" ]; then
	make install >make_install.log 2>&1
else
	env -i "${APACHE_PREFIX}/bin/apachectl" stop >/dev/null 2>&1 || true
	#killall -KILL httpd >/dev/null 2>&1 || true
	make install >make_install.log 2>&1
	env -i "${APACHE_PREFIX}/bin/apachectl" start
fi

echo
echo -n "Configuring PECL modules..."
mkdir -p "${PHP_PREFIX}/lib/php_mod"
cat "${PHP_PREFIX}/lib/php-web/php.ini" | grep -v '^extension' >/tmp/php.ini
mv -f /tmp/php.ini "${PHP_PREFIX}/lib/php-web/php.ini"
echo "extension_dir = ${PHP_PREFIX}/lib/php_mod" >>"${PHP_PREFIX}/lib/php-web/php.ini"
mkdir -p mod
cd mod
for foo in $PHP_PECL; do
	PECL_CONFIGURE=()
	if [ `echo "$foo" | grep -c '\.git$'` = "1" ]; then
		# git repo
		NAME=`echo "$foo" | sed -e 's#.*/##;s/\.git$//'`
		echo -n "$NAME"
		if [ -d "$NAME" ]; then
			cd "$NAME"
			git pull -n -q
		else
			git clone -q "$foo" "$NAME"
			cd "$NAME"
		fi
		echo -n "[git] "
		"${PHP_PREFIX}/bin/phpize" >phpize.log 2>&1 || ( echo -n "[fail] " && continue )
		./configure >configure.log 2>&1 "${PECL_CONFIGURE[@]}"
		if [ "$NAME" = "php-git" ]; then
			# special case, linking ssh2 in php-git is a pain, so we cheat our way out (-Wl required because if using -l libtool will move it)
			sed -r -i 's/^(GIT2_SHARED_LIBADD = .*)$/\1 -Wl,-lssh2/' Makefile
		fi
		make -j"$MAKE_PROCESSES" >make.log 2>&1
		cp modules/* "${PHP_PREFIX}/lib/php_mod"
		cd ..
		continue
	fi
	if [ "$foo" = "memcached/stable" ]; then
		PECL_CONFIGURE+=("--disable-memcached-sasl")
	fi

	echo -n "$foo"
	curl -s "https://pecl.php.net/get/$foo" | tar xzf /dev/stdin >/dev/null 2>&1
	foo=`echo "$foo" | cut -d/ -f1`
	dr=`find . -name "$foo*" -type d | head -n1`
	if [ x"$dr" = x ]; then
		continue;
	fi
	pecl_version=`echo "$dr" | $SED -e 's/^.*-//'`
	cd $dr
	echo -n "[$pecl_version] "
	"${PHP_PREFIX}/bin/phpize" >phpize.log 2>&1 || ( echo -n "[fail] " && continue )
	./configure >configure.log 2>&1 "${PECL_CONFIGURE[@]}"
	make -j"$MAKE_PROCESSES" >make.log 2>&1
	cp modules/* "${PHP_PREFIX}/lib/php_mod"
	cd ..
done
cd ..
for foo in ${PHP_PREFIX}/lib/php_mod/*.so; do
	foo=`basename "$foo"`
	if [ x"$foo" = x'*.so' ]; then
		break;
	fi
	echo "extension = $foo" >>"${PHP_PREFIX}/lib/php-web/php.ini"
done

if [ x"$APACHE_PREFIX" = x"none" ]; then
	echo "You will need to fix the FPM binary"
else
	env -i "${APACHE_PREFIX}/bin/apachectl" stop >/dev/null 2>&1 || true
	#killall -KILL httpd >/dev/null 2>&1 || true
	sleep 1s
	#ipcs -s | grep nobody | perl -e 'while (<STDIN>) { @a=split(/\s+/); print `ipcrm sem $a[1]`}'
	env -i "${APACHE_PREFIX}/bin/apachectl" start
fi
echo ""
echo "Installation complete."
