#!/bin/sh

#file path
log_path="${1}"
target_path=`dirname "${log_path}"`
echo "" > "${target_path}/starttime_stationtype_testtype.txt"
handle_log_file()
{
   ( grep "Nests" "${log_path}" | awk '{print $20,$32,$35,$38,$2,$5}' | awk 'FS="\""{print $2,$4,$6,$7}' | grep "^com" | awk -F"\\" '{print $1,$2,$3,$4}' | sed "/;/ s/;//g" | awk '{print NR,$1,$2,$4,$5,$6}' | sort -k4,4 -k1,1n | awk '{print $5,$6,$2,$3,$4}' | uniq -f1 > "${target_path}/result.txt" ) &
   ( grep "Start Test Fixture" "${log_path}" | awk '{print $9,$2,$23,$26}' | awk 'BEGIN {FS="."}{print $1,$7}' | awk -F"-" '{print $5}' | sed '/;/ s/;//g' | sed 's/\\\"//g' > "${target_path}/starttime_stationtype_testtype.txt" ) &
   ( grep ": testMain " "${log_path}" | awk '{print $2,$10,$11,$14,$16}' | awk 'BEGIN {FS="."}{print $1,$3,$7}' | sed "/,/ s/,//g" | awk '{print $1,$2,$3,$4}' > "${target_path}/stage_location_result_id_finishtime.txt" ) &
   wait
   awk '{print $4}' "${target_path}/stage_location_result_id_finishtime.txt" | awk -F":" '{print $1}' | sort -u > "${target_path}/SN.txt"
   station_type=($(awk '{print $1}' "${target_path}/starttime_stationtype_testtype.txt"))
   echo "Handle log file finish !"

}
#menu()
menu()
{
  echo "CAM SN","DUT SN","Station Type","Test Type","Location","Test Stage","Start Time","Finish Time","Test Result","Test Time" > "${target_path}/test.csv"
}
division_sn_for_progress()
{
  echo "division SN start ..."
  total_cnt=`wc -l "${target_path}/SN.txt" | awk '{print $1}'`
  div_sn=$(($total_cnt/3))
  div_sn_cnt=$(($div_sn+2))
  split -$div_sn_cnt "${target_path}/SN.txt" "${target_path}/1.txt"
  echo "division SN finish !!"
}

function handle_single_dut()
{
  local local_cam_id="$1"
  file1="${target_path}/starttime_stationtype_testtype.txt"
  file2="${target_path}/stage_location_result_id_finishtime.txt"
  file3="${target_path}/result.txt"
  pro_file="$2"
  local start_time=($(grep "${local_cam_id}" "${file1}" | awk '{print $2}'))
  local test_type=($(grep "${local_cam_id}" "${file1}" | awk '{print $3}'))
  local test_stage=($(grep "${local_cam_id}" "${file2}" | awk '{print $3}'))
  local location=($(grep "${local_cam_id}" "${file2}" | awk '{print $2}'))
  local finish_time=($(grep "${local_cam_id}" "${file2}" | awk '{print $1}'))
  local dut_id=($(grep "${local_cam_id}" "${file2}" | awk '{print $4}' | awk -F":" '{print $2}'))
  if [ "${#dut_id[*]}" -eq 0 ];then
	dut_id=(${local_cam_id})
  fi

  local location_cnt=($(grep "${local_cam_id}" "${file2}" | awk '{print $2}' | sort -u))

  if [ "${#location_cnt[*]}" -eq 2 ];then
      local test_result=($(grep "${dut_id[0]}" "${file3}" | grep -E "${location_cnt[0]}|${location_cnt[1]}" | awk '{print $3}'))
  else
      local test_result=($(grep "${dut_id[0]}" "${file3}" | awk '{print $3}'))
  fi
  if [ "${#finish_time[*]}" -gt "${#test_result[*]}" ];then
      result_cam=($(grep "${local_cam_id}" "${file3}" | awk '{print $3}'))
      local test_result=(${result_cam[*]} ${test_result[*]})
      if [ "${#finish_time[*]}" -gt "${#test_result[*]}" ];then
        result_cam=($(grep "${local_cam_id}" "${file3}" | awk '{print $3}'))
        test_result=(${result_cam[*]} ${test_result[*]})
      fi
  fi
  if [ "${#start_time[*]}" -lt "${#finish_time[*]}" ];then
    start_time=('a' ${start_time[*]})
  fi
  if [ "${#start_time[*]}" -eq 3 -a "${#finish_time[*]}" -eq 2 ];then
     finish_time=($(grep "${dut_id[0]}" "${file3}" | awk '{print $1}' | awk -F"." '{print $1}'))
     test_stage=(${test_stage[0]} Testing ${test_stage[1]})
     location=($(grep "${dut_id[0]}" "${file3}" | awk '{print $2}'))
  fi
  for((t=0;t<"${#finish_time[*]}";t++))
  do
     if [ "${start_time[${t}]}" = 'a' ];then
        time_diff=""
        echo "${local_cam_id}","${dut_id[t]}","${station_type[0]}","${test_type[0]}","${location[t]}","${test_stage[t]}","","${finish_time[t]}","${test_result[t]}","${time_diff}" >> "$pro_file"
     else
       local start_time_stamp=`date -j -f"%H:%M:%S" "${start_time[t]}" +%s`
       local finish_time_stamp=`date -j -f"%H:%M:%S" "${finish_time[t]}" +%s`
       time_diff=$((${finish_time_stamp} - ${start_time_stamp}))
       echo "${local_cam_id}","${dut_id[0]}","${station_type[0]}","${test_type[t]}","${location[t]}","${test_stage[${t}]}","${start_time[t]}","${finish_time[t]}","${test_result[t]}","${time_diff}" >> "$pro_file"
     fi
  done
  ( echo "single DUT information is handling ......" )
}
sort_file()
{
  echo "sort file start..."
  menu
  cat "${target_path}/produce_2.txt" "${target_path}/produce_3.txt" >> "${target_path}/produce_1.txt"
  sort -t"," -k8 "${target_path}/produce_1.txt" >> "${target_path}/test.csv"
  echo "sort file finish !!"
}
function main()
{
  handle_log_file
  division_sn_for_progress
  
  ( cam_id_one=($(awk '{print $1}' "${target_path}/1.txtaa"))
    for((a=0;a<"${#cam_id_one[*]}";a++))
    do
       ( handle_single_dut ${cam_id_one[a]} "${target_path}/produce_1.txt" )
    done
  ) &
  ( cam_id_two=($(awk '{print $1}' "${target_path}/1.txtab"))
    for((b=0;b<"${#cam_id_two[*]}";b++))
    do
       ( handle_single_dut ${cam_id_two[b]} "${target_path}/produce_2.txt" )
    done
  ) &
  ( cam_id_three=($(awk '{print $1}' "${target_path}/1.txtac"))
  for((c=0;c<"${#cam_id_three[*]}";c++))
  do
     ( handle_single_dut ${cam_id_three[c]} "${target_path}/produce_3.txt" )
  done
  ) &

  wait
  sort_file
  rm "${target_path}/starttime_stationtype_testtype.txt"
  rm "${target_path}/stage_location_result_id_finishtime.txt"
  rm "${target_path}/result.txt"
  rm "${target_path}/SN.txt"
  rm "${target_path}/1.txtaa"
  rm "${target_path}/1.txtab"
  rm "${target_path}/1.txtac"
  rm "${target_path}/produce_1.txt"
  rm "${target_path}/produce_2.txt"
  rm "${target_path}/produce_3.txt"
}
main
