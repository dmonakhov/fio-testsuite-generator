#!/bin/bash

set -e

DIR=`pwd`
DIR=$DIR/$(dirname $0)

function raw_consolidate()
{
    mkdir -p report/raw-data
    for d in `find groups -mindepth 1 -maxdepth 1 -type d`;
    do
	if [ -d "$d" ] && [ -d "$d/results" ];then
	    echo $d/results
	    pushd $d/results
	    truncate -s 0 results.txt
	    for i in `ls *.json`
	    do
		$DIR/fio_report_parse.sh $i >> results.txt
	    done
	    popd
	    cp -r $d report/raw-data/
	fi
    done
}

function gen_groups ()
{
    cat groups/*/results/results.txt   > tmp/raw_results.txt

    cat tmp/raw_results.txt | \
	sed  -e 's/--/  /g' | \
	sed  -e 's/-n/ threads /g' | \
	sed  -e 's/-d/ depth /g' | \
	sed  -e 's/-b4k/ b4k/g' > tmp/all_results.txt
    unlink tmp/raw_results.txt
    cat tmp/all_results.txt | gawk '{print $1}' | sort | uniq >    tmp/group-env.txt
    cat tmp/all_results.txt | gawk '{print $2}' | sort | uniq >    tmp/group-op.txt
    cat tmp/all_results.txt | gawk '{print $4}' | sort -g | uniq > tmp/group-threads.txt
    cat tmp/all_results.txt | gawk '{print $6}' | sort -g | uniq > tmp/group-depth.txt

    for grp in `cat tmp/group-env.txt`
    do
	for op in `cat tmp/group-op.txt`
	do
	    cat tmp/all_results.txt | grep $grp | grep $op > tmp.txt || continue
	    mkdir -p report/ops/$op
	    
	    for d in `cat tmp/group-depth.txt`
	    do
		mkdir -p report/ops/$op/depth-$d
		cat tmp.txt | grep "depth $d " | sort -k4  -g  > tmp/$grp-$op-d$d.txt
		#cp tmp/$grp-$op-d$d.txt $grp/$op-d$d.txt
		cp tmp/$grp-$op-d$d.txt report/ops/$op/depth-$d/$grp-$op-d$d.txt
		unlink tmp/$grp-$op-d$d.txt
	    done
	    for t in `cat tmp/group-threads.txt`
	    do
		mkdir -p report/ops/$op/threads-$t
		cat tmp.txt | grep "threads $t " | sort -k6  -g  > tmp/$grp-$op-n$t.txt
		#cp tmp/$grp-$op-n$t.txt  $grp/$op-n$t.txt
		cp tmp/$grp-$op-n$t.txt  report/ops/$op/threads-$t/$grp-$op-n$t.txt
		unlink tmp/$grp-$op-n$t.txt
	    done
	    unlink tmp.txt
	done
    done
}

function gen_graphs ()
{
    mkdir -p report/img
    pushd report
    for i in `find ops -type d  -maxdepth 2 -mindepth 2`
    do
	valid_data="n"
	sep=""
	pushd $i
	name=`echo $i | tr '/' '-'`

	x_row="4"
	units="threads"
	echo "$i" | grep '/depth-' || x_row="6"
	echo "$i" | grep '/depth-' || units="depth"

	y_row="8"
	echo "$i" | grep write && y_row="12"

	column="i 0 u ${x_row}:${y_row} with linespoints title columnheader(1)"

	cmd="plot "
	pt_idx=1
	for f in `ls *.txt| sort`
	do
	    # Skip empty datasets
	    [ `cat $f | wc -l` -gt 1 ] || continue
	    
	    cmd="$cmd $sep '$f' $column pt $pt_idx"
	    pt_idx=$((pt_idx+1))
	    sep=","
	    valid_data="y"
	    done
	if [ "$valid_data" == 'y' ]
	then
	    cat > graph.plt <<EOF
# graph-$i
set terminal png size 1024, 800
set title "$name"
set output "$name.png"
set ylabel "IOPS"
set xlabel "$units"

EOF
	    echo $cmd >> graph.plt
	    gnuplot < graph.plt
	    mv $name.png ../../../img/
	fi
	popd
    done
    popd

}
function gen_org_report()
{
    if [ ! -f "report/report_header.org" ]
    then
	local env=`mktemp /tmp/XXXXXXX.env`
	echo "USER=$USER"  >> $env
	echo "HOSTNAME=$HOSTNAME"  >> $env
	j2 --format=env templates/report_header.org.j2 $env > report/report_header.org
    fi
    cat report/report_header.org > report/result.org
    echo "" >> report/result.org
    echo "* Performance results" >> report/result.org
    
    for op in `cat tmp/group-op.txt`
    do
	echo "** $op" >> report/result.org
	echo "*** Raw data [[./ops/$op][raw data]]" >> report/result.org
	for i in `ls report/img/ops-$op-*.png | sort -V`
	do
	    name=$(basename $i)
	    cat >> report/result.org <<EOF
#+NAME:   fig:$name
     [[./img/$name]]
EOF
	done
    done
    emacs report/result.org --batch -f org-html-export-to-html --kill
}

mkdir -p tmp
raw_consolidate
gen_groups
gen_graphs
gen_org_report
