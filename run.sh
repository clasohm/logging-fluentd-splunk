#!/bin/bash

# Based on
# https://github.com/openshift/origin-aggregated-logging/blob/release-3.11/fluentd/run.sh

CFG_DIR=/etc/fluent/configs.d

echo "============================="
echo "Fluentd logs have been redirected to: $LOGGING_FILE_PATH"
echo "If you want to print out the logs, use command:"
echo "oc exec <pod_name> -- logs"
echo "============================="

touch $LOGGING_FILE_PATH; exec >> $LOGGING_FILE_PATH 2>&1

fluentdargs="--no-supervisor"
if [[ $VERBOSE ]]; then
  set -ex
  fluentdargs="$fluentdargs -vv"
  echo ">>>>>> ENVIRONMENT VARS <<<<<"
  env | sort
  echo ">>>>>>>>>>>>><<<<<<<<<<<<<<<<"
else
  set -e
fi

IPADDR4=`/usr/sbin/ip -4 addr show dev eth0 | grep inet | sed -e "s/[ \t]*inet \([0-9.]*\).*/\1/"`
IPADDR6=`/usr/sbin/ip -6 addr show dev eth0 | grep inet6 | sed "s/[ \t]*inet6 \([a-f0-9:]*\).*/\1/"`
export IPADDR4 IPADDR6

BUFFER_SIZE_LIMIT=${BUFFER_SIZE_LIMIT:-16777216}

# Check the existing main fluent.conf has the @OUTPUT label
# If it exists, we could use the label and take advantage.
# If not, give up one output tag per plugin for now.
output_label=$( egrep "<label @OUTPUT>" $CFG_DIR/../fluent.conf || : )

FILE_BUFFER_PATH=/var/lib/fluentd

# Get the available disk size.
DF_LIMIT=$(df -B1 $FILE_BUFFER_PATH | grep -v Filesystem | awk '{print $2}')
DF_LIMIT=${DF_LIMIT:-0}
if [ $DF_LIMIT -eq 0 ]; then
    echo "ERROR: No disk space is available for file buffer in $FILE_BUFFER_PATH."
    exit 1
fi
# Determine final total given the number of outputs we have.
TOTAL_LIMIT=$(echo ${FILE_BUFFER_LIMIT:-2Gi} | sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc) || :
if [ $TOTAL_LIMIT -le 0 ]; then
    echo "ERROR: Invalid file buffer limit ($FILE_BUFFER_LIMIT) is given.  Failed to convert to bytes."
    exit 1
fi

NUM_OUTPUTS=1

# If forward and secure-forward outputs are configured, add them to NUM_OUTPUTS.
forward_files=$( grep -l "@type .*forward" ${CFG_DIR}/*/* 2> /dev/null || : )
for afile in ${forward_files} ; do
    file=$( basename $afile )
    grep "@type .*forward" $afile | while read -r line; do
        if [ $( expr "$line" : "^ *#" ) -eq 0 ]; then
            NUM_OUTPUTS=$( expr $NUM_OUTPUTS + 1 )
        fi
    done
done

TOTAL_LIMIT=$(expr $TOTAL_LIMIT \* $NUM_OUTPUTS) || :
if [ $DF_LIMIT -lt $TOTAL_LIMIT ]; then
    echo "WARNING: Available disk space ($DF_LIMIT bytes) is less than the user specified file buffer limit ($FILE_BUFFER_LIMIT times $NUM_OUTPUTS)."
    TOTAL_LIMIT=$DF_LIMIT
fi

BUFFER_SIZE_LIMIT=$(echo $BUFFER_SIZE_LIMIT |  sed -e "s/[Kk]/*1024/g;s/[Mm]/*1024*1024/g;s/[Gg]/*1024*1024*1024/g;s/i//g" | bc)
BUFFER_SIZE_LIMIT=${BUFFER_SIZE_LIMIT:-16777216}

# TOTAL_BUFFER_SIZE_LIMIT per buffer
TOTAL_BUFFER_SIZE_LIMIT=$(expr $TOTAL_LIMIT / $NUM_OUTPUTS) || :
if [ -z $TOTAL_BUFFER_SIZE_LIMIT -o $TOTAL_BUFFER_SIZE_LIMIT -eq 0 ]; then
    echo "ERROR: Calculated TOTAL_BUFFER_SIZE_LIMIT is 0. TOTAL_LIMIT $TOTAL_LIMIT is too small compared to NUM_OUTPUTS $NUM_OUTPUTS. Please increase FILE_BUFFER_LIMIT $FILE_BUFFER_LIMIT and/or the volume size of $FILE_BUFFER_PATH."
    exit 1
fi
BUFFER_QUEUE_LIMIT=$(expr $TOTAL_BUFFER_SIZE_LIMIT / $BUFFER_SIZE_LIMIT) || :
if [ -z $BUFFER_QUEUE_LIMIT -o $BUFFER_QUEUE_LIMIT -eq 0 ]; then
    echo "ERROR: Calculated BUFFER_QUEUE_LIMIT is 0. TOTAL_BUFFER_SIZE_LIMIT $TOTAL_BUFFER_SIZE_LIMIT is too small compared to BUFFER_SIZE_LIMIT $BUFFER_SIZE_LIMIT. Please increase FILE_BUFFER_LIMIT $FILE_BUFFER_LIMIT and/or the volume size of $FILE_BUFFER_PATH."
    exit 1
fi
export BUFFER_QUEUE_LIMIT BUFFER_SIZE_LIMIT

if [[ $DEBUG ]] ; then
    exec scl enable rh-ruby25 "fluentd $fluentdargs" > /var/log/fluentd.log 2>&1
else
    exec scl enable rh-ruby25 "fluentd $fluentdargs"
fi
