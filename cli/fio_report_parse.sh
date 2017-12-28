#!/bin/bash

op_cmd='" " + (.iops|tostring) + " " + (.slat.mean|tostring) + " " + (.clat.mean|tostring) + " " + (.lat.mean|tostring)'


#jq '.jobs[0]|  .jobname  + " " + (.read.iops|tostring)  + " " + (.write.iops|tostring)'

name=`jq ".jobs[0].jobname" $1`
read=`jq ".jobs[0].read| $op_cmd" $1`
write=`jq ".jobs[0].write| $op_cmd" $1`


echo $name $read $write | tr -d '"' 
