#!/bin/sh -x

# This will run tcpdump and offload it to the specified S3 bucket, if the ENV TCPDUMP_BUCKET is supplied.
if [ ! -z ${TCPDUMP_BUCKET+x} ] ; then
  echo "Running the tcpdump process..."
  echo "$TCPDUMP_BUCKET" > /tmp/bucket
  (tcpdump -nn -w /tmp/tcpdump-$HOSTNAME-%s -W 300 -z "/files/tcpdump_push.sh" -Z root -G 30 -i eth0) &
fi

# This will run a memory stress test if the ENV $STRESS_MEMORY_TO is supplied.
if [ ! -z ${STRESS_MEMORY_TO+x} ] ; then
  echo "Adding memory stress processes..."
  (stress-ng --vm-bytes  "$STRESS_MEMORY_TO" --vm-keep -m 1) &
fi

# This will delete the index.html file, to simulate a failing of a healthcheck, if the ENV $DELETE_INDEX_PAGE_AFTER_SECONDS is supplied.
if [ ! -z ${DELETE_INDEX_PAGE_AFTER_SECONDS+x} ] ; then
  echo "Will delete the index page after $DELETE_INDEX_PAGE_AFTER_SECONDS seconds..."
  (sleep "$DELETE_INDEX_PAGE_AFTER_SECONDS" && rm /usr/share/nginx/html/index.html) &
fi

nohup /usr/sbin/sshd
nginx -g 'daemon off;'
