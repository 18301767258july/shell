#!/bin/sh

#file path
log_path="${1}"
target_path=`dirname "${log_path}"`
echo "Station","offline time","online time","total time" > "${target_path}/result.csv"


grep "setState:Scheduled Offline, reason" "${log_path}" | awk '{print $2,$8}' | sed 's/]//g'> "${target_path}/off.txt"
grep "setState:Scheduled Online, reason: User" "${log_path}" | awk '{print $2,$8}' | sed 's/]//g'> "${target_path}/on.txt"

#all stations  
station_off=($(awk '{print $2}' "${target_path}/off.txt" | awk -F"." '{print $2}' | sort -u)) 
#handle every station
for((n=0;n<"${#station_off[*]}";n++))
do
      #2102.1
      off_time_1=($(grep "${station_off[n]}.1" "${target_path}/off.txt" | awk -F"." '{print $1}'))
      on_time_1=($(grep "${station_off[n]}.1" "${target_path}/on.txt" | awk -F"." '{print $1}'))
      #2102.2
      off_time_2=($(grep "${station_off[n]}.2" "${target_path}/off.txt" | awk -F"." '{print $1}'))
      on_time_2=($(grep "${station_off[n]}.2" "${target_path}/on.txt" | awk -F"." '{print $1}'))
      
      #handle 2102.1
       ( for((x=0;x<"${#off_time_1[*]}";x++))
        do
            for((i=0;i<"${#on_time_1[*]}";i++))
            do
              time_num=$((`date -j -f"%H:%M:%S" ${on_time_1[i]} +%s` - `date -j -f"%H:%M:%S" ${off_time_1[x]} +%s`))
              if [ ${time_num} -gt 0 ];then
                break
              fi
            done
            echo "${station_off[n]}.1",${off_time_1[x]},${on_time_1[i]},${time_num} >> "${target_path}/result.csv"
        done
        ) &
       #handle 2102.2
       (
       for((y=0;y<"${#off_time_2[*]}";y++))
        do
            for((j=0;j<"${#on_time_2[*]}";j++))
            do
              time_num=$((`date -j -f"%H:%M:%S" ${on_time_2[j]} +%s` - `date -j -f"%H:%M:%S" ${off_time_2[y]} +%s`))
              if [ ${time_num} -gt 0 ];then
                break
              fi
            done
            echo "${station_off[n]}.2",${off_time_2[y]},${on_time_2[j]},${time_num} >> "${target_path}/result.csv"
        done
        ) &
done

rm "${target_path}/on.txt"
rm "${target_path}/off.txt"
