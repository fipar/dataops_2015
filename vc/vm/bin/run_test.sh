#!/bin/bash

. worker_pool.sh
export _worker_pool_WORKERS=10
no_of_queries=$(ls queries/*|wc -l)

worker()
{
   query_file=$(ls queries/*|head -$((1 + RANDOM % no_of_queries))|tail -1)
   mysql --ssl=OFF -h 127.0.0.1 drupal < $query_file
}

while [ ! -f /tmp/stop_test ]; do
   _worker_pool_start_worker_or_wait_for_slot worker 
done
