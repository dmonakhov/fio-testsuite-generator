#! /bin/bash 

set -e
#filename_format=/mnt-smp/$jobnum/file
FIO_JOB_TEMPLATE=templates/fio-job-template.fio.j2
#FIO_JOB_ROOT=/mnt/mnt-smp/
function gen_job () {

	local prefix=$1
	local FIO_IOENGINE=$2
	local FIO_OP=$3
	local FIO_NUMJOBS=$4
	local FIO_IODEPTH=$5
	local FIO_BS=$6

	local FIO_JOB_NAME=$prefix--$FIO_IOENGINE-$FIO_OP-n$FIO_NUMJOBS-d$FIO_IODEPTH-b$FIO_BS

	local FIO_SIZE=100T
	local FIO_FILESIZE=4G
	local FIO_RAMP_TIME=3
	local FIO_RUNTIME=20
	
	local env=`mktemp /tmp/XXXXXXX.env`
	echo "FIO_JOB_NAME=$FIO_JOB_NAME" >> $env
	echo "FIO_IOENGINE=$FIO_IOENGINE" >> $env
	echo "FIO_OP=$FIO_OP" >> $env
	echo "FIO_IODEPTH=$FIO_IODEPTH" >> $env
	echo "FIO_NUMJOBS=$FIO_NUMJOBS" >> $env
	echo "FIO_BS=$FIO_BS" >> $env
	#echo 'FIO_FILENAME_FORMAT=/mnt/vstorage/vols/mnt-smp/$jobnum/file' >> $env
	echo 'FIO_FILENAME_FORMAT=/mnt/mnt-smp/$jobnum/file' >> $env

	echo "FIO_SIZE=$FIO_SIZE" >> $env
	echo "FIO_FILESIZE=$FIO_FILESIZE" >> $env
	echo "FIO_RAMP_TIME=$FIO_RAMP_TIME" >> $env
	echo "FIO_RUNTIME=$FIO_RUNTIME" >> $env

	j2 --format=env $FIO_JOB_TEMPLATE $env  > groups/$prefix/jobs/$FIO_JOB_NAME.fio
	unlink $env
}

function get_jobs_runner ()
{
    local JOB_PREFIX=$1
    local env=`mktemp /tmp/XXXXXXX.env`

    echo "JOB_PREFIX=$JOB_PREFIX" >> $env
    j2 --format=env templates/run_jobs.sh.j2 $env  > groups/run_jobs_$JOB_PREFIX.sh
    chmod +x groups/run_jobs_$JOB_PREFIX.sh
    unlink $env
}

JOB_PREFIX=$1

if [ -z "$JOB_PREFIX" ]; then
    echo "Usage $0 job_prefix"
    exit 1
fi

mkdir -p groups/$JOB_PREFIX/jobs

get_jobs_runner $JOB_PREFIX

for i in 1 2 4 6 8 12 16 24 32 48 64 96
do
    gen_job $JOB_PREFIX sync read   $i 1 4k
    gen_job $JOB_PREFIX sync write  $i 1 4k
    gen_job $JOB_PREFIX sync randread   $i 1 4k
    gen_job $JOB_PREFIX sync randwrite  $i 1 4k

done

for ((i=1;i<256;i=i*2))
do
    gen_job $JOB_PREFIX libaio randread  1 $i 4k
    gen_job $JOB_PREFIX libaio randwrite 1 $i 4k
done

for i in 1 2 4 6 8 12 16 24 32 48 64 96
do
    gen_job $JOB_PREFIX libaio read      $i 2 4k
    gen_job $JOB_PREFIX libaio write     $i 2 4k
    gen_job $JOB_PREFIX libaio randread  $i 2 4k
    gen_job $JOB_PREFIX libaio randwrite $i 2 4k

    gen_job $JOB_PREFIX libaio read      $i 4 4k
    gen_job $JOB_PREFIX libaio write     $i 4 4k
    gen_job $JOB_PREFIX libaio randread  $i 4 4k
    gen_job $JOB_PREFIX libaio randwrite $i 4 4k

    gen_job $JOB_PREFIX libaio read      $i 8 4k
    gen_job $JOB_PREFIX libaio write     $i 8 4k
    gen_job $JOB_PREFIX libaio randread  $i 8 4k
    gen_job $JOB_PREFIX libaio randwrite $i 8 4k

    gen_job $JOB_PREFIX libaio read      $i 16 4k
    gen_job $JOB_PREFIX libaio write     $i 16 4k
    gen_job $JOB_PREFIX libaio randread  $i 16 4k
    gen_job $JOB_PREFIX libaio randwrite $i 16 4k

    gen_job $JOB_PREFIX libaio read      $i 32 4k
    gen_job $JOB_PREFIX libaio write     $i 32 4k
    gen_job $JOB_PREFIX libaio randread  $i 32 4k
    gen_job $JOB_PREFIX libaio randwrite $i 32 4k

    gen_job $JOB_PREFIX libaio read      $i 64 4k
    gen_job $JOB_PREFIX libaio write     $i 64 4k
    gen_job $JOB_PREFIX libaio randread  $i 64 4k
    gen_job $JOB_PREFIX libaio randwrite $i 64 4k

    gen_job $JOB_PREFIX libaio read      $i 128 4k
    gen_job $JOB_PREFIX libaio write     $i 128 4k
    gen_job $JOB_PREFIX libaio randread  $i 128 4k
    gen_job $JOB_PREFIX libaio randwrite $i 128 4k

done



