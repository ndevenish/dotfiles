#!/bin/bash

# Open a logfile from an epoch timestamp
logfile() {
  TIMESTAMP=${1:-$(date +%s)}
  LOGFILE=~/log/$(date -r "$TIMESTAMP" "+%Y_%m_%d.md")
  if [[ ! -f ${LOGFILE} ]]; then
    # Create the daily log file
    TEMPLATE=~/log/_daily_template
    # Magic perl to substitude environment variables
    # shellcheck disable=all
    DATE=$(date -r $TIMESTAMP "+%Y-%m-%d") TIME=$(date -r $TIMESTAMP "+%H:%M") perl -pe 's;(\\*)(\$([a-zA-Z_][a-zA-Z_0-9]*)|\$\{([a-zA-Z_][a-zA-Z_0-9]*)\})?;substr($1,0,int(length($1)/2)).($2&&length($1)%2?$2:$ENV{$3||$4});eg' $TEMPLATE >> $LOGFILE
  fi
  subl "$LOGFILE"
}

# Open a daily log file
daily() {
	# TODAY=~/log/$(date "+%Y_%m_%d.md")
	# if [[ ! -f ${TODAY} ]]; then
	# 	# Create the daily log file
	# 	TEMPLATE=~/log/_daily_template
	# 	# Magic perl to substitude environment variables
	# 	DATE=$(date "+%Y-%m-%d") TIME=$(date "+%I:%M") perl -pe 's;(\\*)(\$([a-zA-Z_][a-zA-Z_0-9]*)|\$\{([a-zA-Z_][a-zA-Z_0-9]*)\})?;substr($1,0,int(length($1)/2)).($2&&length($1)%2?$2:$ENV{$3||$4});eg' $TEMPLATE >> $TODAY
	# fi
	# subl $TODAY
  logfile
}

yesterday() {
  time_yesterday=$(date -v -1d -v 9H -v 0M +%s )
  LOGFILE=~/log/$(date -r "$time_yesterday" "+%Y_%m_%d.md")

  # If this was a weekend, only open if we already created one
  if [[ ! $1 == "-f" && $(date -r "$time_yesterday" "+%u" ) -ge 6 ]]; then
    if [[ ! -f $LOGFILE ]]; then
      echo -e "No logfile for $(date -r "$time_yesterday" "+%Y-%m-%d") but is a weekend. Not creating.\n  Pass -f to force."
    fi
  else
    echo "Opening $LOGFILE"
    logfile "$time_yesterday"
  fi
}

tomorrow() {
  logfile "$(date -v +1d -v 9H -v 0M +%s )"
}

logs() {
  sub ~/log
}