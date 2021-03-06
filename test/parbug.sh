#!/bin/bash
totalruns=$1
threads=$2
containers=()
cuses=()
ctimes=()

callservice() {
  totalruns=$1
  threadid=$2
  #host=10.0.0.124
  #port=8080
  onesecond=1000
  if [ $threadid -eq 1 ]
  then
    echo "run_id,thread_id,uuid,cputype,cpusteal,vmuptime,pid,cpuusr,cpukrn,elapsed_time,sleep_time_ms"
  fi
  for (( i=1 ; i <= $totalruns; i++ ))
  do
    #CALCS - uncomment JSON line for desired number of calcs
    #(0) - no calcs
    #json={"\"name\"":\"\/proc\/cpuinfo\"",\"calcs\"":0,\"sleep\"":0,\"loops\"":0}

    #(1) - very light calcs
    #json={"\"name\"":\"\/proc\/cpuinfo\"",\"calcs\"":100,\"sleep\"":0,\"loops\"":20}

    #(2) - light calcs 
    json={"\"name\"":"\"\",\"calcs\"":1000,\"sleep\"":0,\"loops\"":20}

    #(3) - medium calcs 
    #json={"\"name\"":\"\/proc\/cpuinfo\"",\"calcs\"":10000,\"sleep\"":0,\"loops\"":20}

    #(4) - somewhat heavy calcs 
    #json={"\"name\"":\"\/proc\/cpuinfo\"",\"calcs\"":25000,\"sleep\"":0,\"loops\"":20}

    #(5) - heavy calcs 
    #json={"\"name\"":\"\/proc\/cpuinfo\"",\"calcs\"":100000,\"sleep\"":0,\"loops\"":20}

    #(6) - many calcs no memory stress - results in more kernel time
    #json={"\"name\"":\"\/proc\/cpuinfo\"",\"calcs\"":20,\"sleep\"":0,\"loops\"":500000}

    #(7) - many calcs low memory stress
    #json={"\"name\"":\"\/proc\/cpuinfo\"",\"calcs\"":100,\"sleep\"":0,\"loops\"":100000}

    #(8) - many calcs higher memory stress
    #json={"\"name\"":\"\/proc\/cpuinfo\"",\"calcs\"":10000,\"sleep\"":0,\"loops\"":1000}

    time1=( $(($(date +%s%N)/1000000)) )
    #uuid=`curl -H "Content-Type: application/json" -X POST -d "{\"name\": \"Fred\"}" https://ue5e0irnce.execute-api.us-east-1.amazonaws.com/test/test 2>/dev/null | cut -d':' -f 3 | cut -d'"' -f 2` 
    output=`curl -H "Content-Type: application/json" -X POST -d  $json https://ue5e0irnce.execute-api.us-east-1.amazonaws.com/test/test 2>/dev/null`
    #output=`curl -H "Content-Type: application/json" -X POST -d  $json https://ue5e0irnce.execute-api.us-east-1.amazonaws.com/test/test 2>/dev/null | cut -d':' -f 3 | cut -d'"' -f 2` 

    # parsing when /proc/cpuinfo is not requested  
    #uuid=`echo $output | cut -d':' -f 3 | cut -d'"' -f 2`
    #cpuusr=`echo $output | cut -d':' -f 4 | cut -d',' -f 1`
    #cpukrn=`echo $output | cut -d':' -f 5 | cut -d',' -f 1`
    #pid=`echo $output | cut -d':' -f 6 | cut -d',' -f 1`
    #cputype="unknwn"

    # parsing when /proc/stat is requested
    #uuid=`echo $output | cut -d',' -f 2 | cut -d':' -f 2 | cut -d'"' -f 2`
    #cpuusr=`echo $output | cut -d',' -f 3 | cut -d':' -f 2`
    #cpukrn=`echo $output | cut -d',' -f 4 | cut -d':' -f 2 | cut -d'"' -f 2`
    #pid=`echo $output | cut -d',' -f 5 | cut -d':' -f 2 | cut -d'"' -f 2`
    #cpusteal=`echo $output | cut -d'"' -f 4 | cut -d' ' -f 9`
    #cputype="unknwn"

    echo $output | cut -d',' -f 4
    thing=`echo $output | cut -d',' -f 4 | cut -d'"' -f 2`
        echo $output
    if [ $thing != "uuid" ]
    then
        echo "ERROR!=$thing"
        echo $output
    fi
    exit
	
    # parsing when /proc/cpuinfo is requested
    uuid=`echo $output | cut -d',' -f 4 | cut -d':' -f 2 | cut -d'"' -f 2`
    cpuusr=`echo $output | cut -d',' -f 5 | cut -d':' -f 2`
    cpukrn=`echo $output | cut -d',' -f 6 | cut -d':' -f 2 | cut -d'"' -f 2`
    pid=`echo $output | cut -d',' -f 7 | cut -d':' -f 2 | cut -d'"' -f 2`
    cputype=`echo $output | cut -d',' -f 1 | cut -d':' -f 7 | cut -d'\' -f 1 | xargs`
    cpusteal=`echo $output | cut -d',' -f 15 | cut -d':' -f 2`
    vuptime=`echo $output | cut -d',' -f 16 | cut -d':' -f 2`
    
    time2=( $(($(date +%s%N)/1000000)) )
    elapsedtime=`expr $time2 - $time1`
    sleeptime=`echo $onesecond - $elapsedtime | bc -l`
    sleeptimems=`echo $sleeptime/$onesecond | bc -l`
    echo "$i,$threadid,$uuid,$cputype,$cpusteal,$vuptime,$pid,$cpuusr,$cpukrn,$elapsedtime,$sleeptimems"
    echo "$uuid,$elapsedtime,$vuptime" >> .uniqcont
    if (( $sleeptime > 0 ))
    then
      sleep $sleeptimems
    fi
  done
}
export -f callservice

runsperthread=`echo $totalruns/$threads | bc -l`
runsperthread=${runsperthread%.*}
date
echo "Setting up test: runsperthread=$runsperthread threads=$threads totalruns=$totalruns"
for (( i=1 ; i <= $threads ; i ++))
do
  arpt+=($runsperthread)
done
parallel --no-notice -j $threads -k callservice {1} {#} ::: "${arpt[@]}"
exit

# determine unique number of containers used or created
filename=".uniqcont"
while read -r line
do
    uuid=`echo $line | cut -d',' -f 1`
    time=`echo $line | cut -d',' -f 2`
    host=`echo $line | cut -d',' -f 3`
    alltimes=`expr $alltimes + $time`
    #echo "Uuid read from file - $uuid"
    # if uuid is already in array
    found=0
    for ((i=0;i < ${#containers[@]};i++)) {
        if [ "${containers[$i]}" == "${uuid}" ]; then
            (( cuses[$i]++ ))
            ctimes[$i]=`expr ${ctimes[$i]} + $time`
            found=1
        fi
    }
    if [ $found != 1 ]; then
        containers+=($uuid)
        chosts+=($host)
        cuses+=(1)
        ctimes+=($time)
    fi


    hfound=0
    for ((i=0;i < ${#hosts[@]};i++)) {
        if [ "${hosts[$i]}" == "${host}"  ]; then
            (( huses[$i]++ ))
            htimes[$i]=`expr ${htimes[$i]} + $time`
            hfound=1
        fi
    }
    if [ $hfound != 1 ]; then
        hosts+=($host)
        huses+=(1)
        htimes+=($time)
        #hcontainers+=($uuid)
    fi
    #if [[ " ${containers[@]} " =~ " ${uuid} " ]]; then
    #  containers+=($uuid)
    #fi
    # add element to array if not already in array
    #if [[ ! " ${containers[@]} " =~ " ${uuid} " ]]; then
    #  containers+=($uuid)
    #fi
done < "$filename"
#echo "Containers=${#containers[@]}"
runspercont=`echo $totalruns / ${#containers[@]} | bc -l`
runsperhost=`echo $totalruns / ${#hosts[@]} | bc -l`
#echo "Runs per containers=$runspercont"
avgtime=`echo $alltimes / $totalruns | bc -l`
#echo "Average time=$avgtime"
rm .uniqcont
echo "uuid,host,uses,totaltime,avgruntime_cont,uses_minus_avguses_sq"
total=0
for ((i=0;i < ${#containers[@]};i++)) {
  avg=`echo ${ctimes[$i]} / ${cuses[$i]} | bc -l`
  stdiff=`echo ${cuses[$i]} - $runspercont | bc -l` 
  stdiffsq=`echo "$stdiff * $stdiff" | bc -l` 
  total=`echo $total + $stdiffsq | bc -l`
  #echo "$total + $stdiffsq"
  echo "${containers[$i]},${chosts[$i]},${cuses[$i]},${ctimes[$i]},$avg,$stdiffsq"
  #echo "${containers[$i]},${cuses[$i]},$avg"
}
stdev=`echo $total / ${#containers[@]} | bc -l`
#echo "containers,avgruntime,runs_per_container,stdev"
#echo "${#containers[@]},$avgtime,$runspercont,$stdev"
# hosts info
echo "host,uses,totaltime,avgruntime_host,uses_minus_avguses_sq"
total=0
for ((i=0;i < ${#hosts[@]};i++)) {
  avg=`echo ${htimes[$i]} / ${huses[$i]} | bc -l`
  stdiff=`echo ${huses[$i]} - $runsperhost | bc -l` 
  stdiffsq=`echo "$stdiff * $stdiff" | bc -l` 
  total=`echo $total + $stdiffsq | bc -l`
  echo "${hosts[$i]},${huses[$i]},${htimes[$i]},$avg,$stdiffsq"
}
stdevhost=`echo $total / ${#hosts[@]} | bc -l`
#echo "hosts,avgruntime,runs_per_host,stdev"
#echo "${#hosts[@]},$avgtime,$runsperhost,$stdev"
echo "containers,hosts,avgruntime,runs_per_container,runs_per_cont_stdev,runs_per_host,runs_per_host_stdev"
echo "${#containers[@]},${#hosts[@]},$avgtime,$runspercont,$stdev,$runsperhost,$stdevhost"



#echo "Standard deviation (runs per container)=$stdev"
#echo "lower is better"

# determine unique number of hosts used
#filename=".uniqhost"
#while read -r line
#do
#    vm=`echo $line | cut -d',' -f 1`
#    uuid=`echo $line | cut -d',' -f 1`
#    time=`echo $line | cut -d',' -f 1`
#done < "$filename"






