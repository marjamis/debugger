#!/bin/sh

(
echo $1
gzip $1
aws s3 cp $1.gz s3://$(cat /tmp/bucket)/tcpdumps/
) &>/proc/1/fd/0
