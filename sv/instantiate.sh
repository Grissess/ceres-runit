#!/bin/sh

if [ -z "$SVDIR" ]; then
	echo -e "\x1b[1;31mPlease specify SVDIR as you would for sv\x1b[m"
	exit 1
fi

if [ -z "$1" ]; then
	echo "usage: $0 servicename-param"
	echo
	echo "available servicenames:"
	ls -A "$SVDIR" | grep '^\.' | sed 's/^.//'
	exit 1
fi

SVNAME="$(echo $1 | sed 's/-.*//')"

if ! [ -d ${SVDIR}/.${SVNAME} ]; then
	echo -e "\x1b[1;31m$SVNAME does not name a service\x1b[m"
	exit 1
fi

if ! [ -x ${SVDIR}/.${SVNAME}/run ]; then
	echo -e "\x1b[1;31m$SVNAME has no executable run"
	exit 1
fi

mkdir -p "$SVDIR/$1/log"
touch "$SVDIR/$1/down"

do_link() {
	if [ -L "$2" ]; then
		echo -e "\x1b[1;33mLink exists, removing to redirect\x1b[m"
		rm "$2"
	fi
	if [ -e "$2" ]; then
		echo -e "\x1b[1;31mPath $2 is already a normal file, skipping\x1b[m"
	else
		ln -s "$1" "$2"
	fi
}

do_link "../.${SVNAME}/run" "${SVDIR}/$1/run"
do_link "../../.log/run" "${SVDIR}/$1/log/run"
if [ -x ${SVDIR}/.${SVNAME}/finish ]; then
do_link "../.${SVNAME}/finish" "${SVDIR}/$1/finish"
else
	do_link "../.log/serv_finish" "${SVDIR}/$1/finish"
fi

ls -l "${SVDIR}/$1"
