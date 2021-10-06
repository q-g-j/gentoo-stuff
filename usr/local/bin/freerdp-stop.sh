#!/bin/bash
kill $(ps ax | grep /bin/bash | grep freerdp-start.sh | grep -v grep | awk '{ print $1 }')
kill $(ps ax | grep freerdp-shadow-cli | grep -v grep | awk '{ print $1 }')
