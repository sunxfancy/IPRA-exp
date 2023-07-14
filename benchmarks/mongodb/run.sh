#!/bin/bash
pwd=`pwd`

function start_mongod() {
    if kill -9 "$(pgrep mongod)" 1>/dev/null 2>&1 ; then
        sleep 5 # wait 10 seconds for the previous server to stop
    fi
    local -r mongod_dir="$1$2"
    local -r name="$3"
    mkdir -p "$pwd/${mongod_dir}/"
    rm -rf $pwd/${mongod_dir}/data
    mkdir -p $pwd/${mongod_dir}/data
    echo "Starting mongod in ${mongod_dir} ..."
    echo "${MYPWD}/$1/install/bin/${name}" --dbpath=$pwd/${mongod_dir}/data --pidfilepath=$pwd/${mongod_dir}/mongod.pid --bind_ip=$pwd/${mongod_dir}/mongod.sock --unixSocketPrefix=$pwd/${mongod_dir} --fork --logpath=$pwd/${mongod_dir}/data/mongod.log
    "${MYPWD}/$1/install/bin/${name}" --dbpath=$pwd/${mongod_dir}/data --pidfilepath=$pwd/${mongod_dir}/mongod.pid --bind_ip=$pwd/${mongod_dir}/mongod.sock --unixSocketPrefix=$pwd/${mongod_dir} --fork --logpath=$pwd/${mongod_dir}/data/mongod.log
    echo "Sleeping 2 seconds to wait for server up ..." 
    sleep 2
}

function stop_mongod() {
  local -r mongod_dir="$1"
  kill -9 `cat $pwd/${mongod_dir}/mongod.pid`
  sleep 3
}

# run one time
function run() {
    local -r mongod_dir="$1$2"
    local -r mongod_name="mongod$2"
    start_mongod $1 $2 "$mongod_name"
    echo "Running benchmarking ... $pwd/../mongo-perf-master"
    cd $pwd/../mongo-perf-master && python benchrun.py -f testcases/simple_insert.js  -t 1 --host=$pwd/${mongod_dir}/mongod.sock -s "${MYPWD}/$1/install/bin/mongo"
    stop_mongod "$mongod_dir"
}

# run in stat mode
function run_bench() {
    local -r mongod_dir="$2$3"
    local -r mongod_name="mongod$3"
    start_mongod $2 $3 "$mongod_name"
    echo "Running benchmarking ... $pwd/../mongo-perf-master"
    cd $pwd/../mongo-perf-master && \
      echo ${PERF_PATH} stat ${PERF_EVENTS} -o "$1" --pid `cat $pwd/${mongod_dir}/mongod.pid`  -- \
        python benchrun.py -f testcases/simple_insert.js  -t 1 --host=$pwd/${mongod_dir}/mongod.sock -s "${MYPWD}/$2/install/bin/mongo" && \
      ${PERF_PATH} stat ${PERF_EVENTS} -o "$1" --pid `cat $pwd/${mongod_dir}/mongod.pid`  -- \
        python benchrun.py -f testcases/simple_insert.js  -t 1 --host=$pwd/${mongod_dir}/mongod.sock -s "${MYPWD}/$2/install/bin/mongo"
    stop_mongod "$mongod_dir"
}

# run in sampling mode
function run_perf() {
    local -r mongod_dir="$2$3"
    local -r mongod_name="mongod$3"
    start_mongod $2 $3 "$mongod_name"
    echo "Running benchmarking ... $pwd/../mongo-perf-master"
    echo ${PERF_PATH} record -e cycles:u -j any -o "$1" --pid `cat $pwd/${mongod_dir}/mongod.pid` 
    cd $pwd/../mongo-perf-master && \
      ${PERF_PATH} record -e cycles:u -j any -o "$1" --pid `cat $pwd/${mongod_dir}/mongod.pid` -- \
        python benchrun.py -f testcases/simple_insert.js  -t 1 --host=$pwd/${mongod_dir}/mongod.sock -s "${MYPWD}/$2/install/bin/mongo" 
    stop_mongod "$mongod_dir"
}

"$@"
