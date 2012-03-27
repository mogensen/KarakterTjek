#!/bin/bash

## No output
exec 1>/dev/null 2>/dev/null

## Directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $DIR/conf

# ========== Temporary files ==========
OLD_OUTPUT=`mktemp ` || exit 1
COOKIE=`mktemp ` || exit 1
TEMPHTML=`mktemp `".html" || exit 1

INDEXFILE="https://stadssb.au.dk/SBSTADSC1P/sb/index.jsp"

date > $LASTLOG

/bin/cp -f $OUTPUT $OLD_OUTPUT 

/usr/bin/curl -s -I -c $COOKIE https://mit.au.dk

POSTTOKEN="brugernavn="$USERNAME"&adgangskode="$PASSWORD"&lang=null&submit_action=login"

## Make sure that the cookie is set before trying to login
/usr/bin/curl -s -L -e $INDEXFILE?brugernavn= -c $COOKIE -b $COOKIE  $INDEXFILE
## Login
/usr/bin/curl -s -L -e $INDEXFILE?brugernavn= -c $COOKIE -b $COOKIE -d $POSTTOKEN $INDEXFILE
## Get grads
/usr/bin/curl -s -L -e $INDEXFILE -c $COOKIE -b $COOKIE "https://stadssb.au.dk/SBSTADSC1P/sb/resultater/studresultater.jsp" > $TEMPHTML
## Parse grads html file througn lynx
/usr/bin/lynx -dump -assume_charset=utf-8 -display_charset=utf-8 $TEMPHTML | /bin/sed 's/^[ \t]*//;s/[ \t]*$//' > $OUTPUT

cat $OUTPUT


if ! /usr/bin/diff -w -B -i -I meta -I Genereret $OLD_OUTPUT $OUTPUT 
then
	echo "Der er blevet lavet en ændring på hjemmesiden for karakterer" 
	echo "Der er blevet lavet en ændring på hjemmesiden for karakterer" >> $LASTLOG

	DIFF="$(/usr/bin/diff -w -B -i -I meta -I Genereret $OLD_OUTPUT $OUTPUT | grep '>'  \
	| sed 's/^>//'   \
	| sed 's/\s*$//g'  \
	| sed 's/\.0$//g'  \
	| sed 's/\([A-F]\)*\s*\([0-9]\)*$//g'  \
	| sed 's/\([0-9]\)\([0-9]\)\.\([0-9]\)\([0-9]\)\.\([0-9]\)\([0-9]\)\([0-9]\)\([0-9]\)//g'  \
	| sed 's/^\s*//g'  \
	| tr -d '\n')"

	echo "$DIFF" | /usr/bin/mail -s "Ændringer på karaktersiden" $MAIL

	echo $DIFF >> $LASTLOG
else 
	echo "Der er ikke nogle ændringer på karaktersiden" >> $LASTLOG
fi

# ========== CLEAN UP ==========
rm $OLD_OUTPUT
rm $COOKIE
rm $TEMPHTML
