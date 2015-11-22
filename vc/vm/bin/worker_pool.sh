#!/bin/bash -x

# worker pool allows a *single threaded* job scheduler to fire up workers as background tasks, up to a configurable
# max number of workers. 
# workers can be any command or bash function/builtin 

# to control worker pool's behavior, the following environment variables can be set: 

# this prefix will be used to create lock files for individual workers
# a lock file will consist of ${_worker_pool_LOCK_PREFIX}.${RANDOM}
[ -z "$_worker_pool_LOCK_PREFIX" ] && _worker_pool_LOCK_PREFIX=/tmp/worker
# the max number of workers to allow
[ -z "$_worker_pool_WORKERS" ] && _worker_pool_WORKERS=4
# we default to silent mode, only producing output on errors
[ -z "$_worker_pool_VERBOSE" ] && _worker_pool_VERBOSE=0
# when all worker slots are used, this marks how many seconds we should sleep
# before checking again for available slots 
[ -z "$_worker_pool_SLEEP_TIME" ] && _worker_pool_SLEEP_TIME=1

# example usage: 
# . worker_pool.sh
# export _worker_pool_WORKERS=2
# for f in $(ls /some/path); do
#    _worker_pool_start_worker_or_wait_for_slot grep PATTERN /some/path/$f > /tmp/${f}.matches
# done

_worker_pool_worker()
{
    lock=$1
    shift
    eval $* 
    [ $_worker_pool_VERBOSE -gt 0 ] && echo "worker $lock finished"
    rm -f $lock
}

_worker_pool_no_of_running_workers()
{
    ls ${_worker_pool_LOCK_PREFIX}* 2>/dev/null|wc -l
}

_worker_pool_start_worker_or_wait_for_slot()
{
    echoed=0
    while [ $(_worker_pool_no_of_running_workers) -ge $_worker_pool_WORKERS ]; do
	[ $echoed -eq 0 ] && {
	    [ $_worker_pool_VERBOSE -gt 0 ] && echo "all workers in use, will wait for a slot">&2
	    echoed=1
	}
	sleep ${_worker_pool_SLEEP_TIME}
	for f in ${_worker_pool_LOCK_PREFIX}*; do
	    [ "$(ps -p $(cat $f) | wc -l)" -gt 1 ] || {
		[ $_worker_pool_VERBOSE -gt 0 ] && echo "removing orphaned lock $f for worker $(cat $f)"
		rm -f $f # remove lock file if worker is no longer running
	    }
        done
    done
    lock=${_worker_pool_LOCK_PREFIX}.$RANDOM
    touch $lock
    [ $_worker_pool_VERBOSE -gt 0 ] && echo "will start worker $lock: $*"
    _worker_pool_worker $lock $* &
    echo $! > $lock
}


