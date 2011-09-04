#! /bin/bash

rcftp=/usr/bin/rcftp

if [ ! -x $rcftp ]; then
        echo You need rcftp installed to start io evaluation
        exit 1
fi

DataSize=100G
Rootdir=/home/ren/eval/v014
Logdir=$Rootdir/log
Configdir=$Rootdir/config
Taskdir=$Rootdir/task

ServIP0=192.168.1.17
ServIP1=192.168.2.17
ServPort=18519

rm -rf $Logdir
rm -rf $Taskdir
rm -rf $Configdir

test -d $Logdir || mkdir -p $Logdir
test -d $Taskdir || mkdir -p $Taskdir
test -d $Configdir || mkdir -p $Configdir


for cbufsiz in 4K 8K 16K 64K 128K 512K 1M
do
	for cbufnum in 1 8 16 64 128 256
	do
		for rcstreamnum in 1 4 8 16
		do
config=$Configdir/rcftp-$cbufsiz-$cbufnum-$rcstreamnum
touch $config
echo "cbufsiz="$cbufsiz >> $config
echo "cbufnum="$cbufnum >> $config
echo "rmtaddrnum=500" >> $config
echo "evbufnum=400" >> $config
echo "recvbufnum=500" >> $config
echo "rcstreamnum="$rcstreamnum >> $config
echo "readernum=8" >> $config
echo "writernum=8" >> $config
echo "directio=yes" >> $config
echo "devzerosiz=10G" >> $config
echo "rdma_qp_sq_depth = 1280" >> $config
echo "rdma_qp_rq_depth = 1280" >> $config
echo "rdma_cq_depth = 2000" >> $config
echo "wc_thread_num = 32" >> $config
echo "wc_event_num = 500" >> $config
		done
	done
done

# task memory to memory
task0=$Taskdir/mem2mem-rput-zeroa-ib0
task1=$Taskdir/mem2mem-rput-zerob-ib1

echo "open 192.168.1.17 18519" >> $task0
echo "user ftp ftp" >> $task0
echo "bin" >> $task0
echo "prompt" >> $task0
echo "lcd /home/ren/data/rftp/source/mem" >> $task0
echo "cd /home/ren/data/rftp/sink/mem" >> $task0
echo "rmput zeroa" >> $task0
echo "bye" >> $task0

echo "open 192.168.2.17 18519" >> $task1
echo "user ftp ftp" >> $task1
echo "bin" >> $task1
echo "prompt" >> $task1
echo "lcd /home/ren/data/rftp/source/mem" >> $task1
echo "cd /home/ren/data/rftp/sink/mem" >> $task1
echo "rmput zeroa" >> $task1
echo "bye" >> $task1

for cbufsiz in 4K 8K 16K 64K 128K 512K 1M
do
	for cbufnum in 1 8 16 64 128 256
	do
		for rcstreamnum in 1 4 8 16
		do
touch $Logdir/mem2mem-$cbufsiz-$cbufnum-$rcstreamnum-ib0.log
touch $Logdir/mem2mem-$cbufsiz-$cbufnum-$rcstreamnum-ib1.log

env RCFTPRC=$Configdir/rcftp-$cbufsiz-$cbufnum-$rcstreamnum $rcftp -n -i -v < $task0 > $Logdir/mem2mem-$cbufsiz-$cbufnum-$rcstreamnum-ib0.log &
pid0=$!
env RCFTPRC=$Configdir/rcftp-$cbufsiz-$cbufnum-$rcstreamnum $rcftp -n -i -v < $task1 > $Logdir/mem2mem-$cbufsiz-$cbufnum-$rcstreamnum-ib1.log &
pid1=$!
wait $pid0 $pid1
		done
	done
done
