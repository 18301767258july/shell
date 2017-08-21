#!/bin/sh

#file path
log_path="${1}"
target_path=`dirname "${log_path}"`

station_type=($(grep "49152" "${log_path}" | grep "GET_STATUS" | tail -1 | awk -F"," '{print $4,$5}'))

echo ${station_type[0]}
echo ${station_type[1]}
