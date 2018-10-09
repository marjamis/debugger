#!/bin/sh

if [ "$TCPDUMP" == "true" ] ; then
  echo "$BUCKET" > /tmp/bucket
  tcpdump -nn -w /tmp/tcpdump-$HOSTNAME-%s -W 300 -z "/files/tcpdump_push.sh" -Z root -G 30 -i eth0 &
fi

nohup /usr/sbin/sshd
nginx -g 'daemon off;'
