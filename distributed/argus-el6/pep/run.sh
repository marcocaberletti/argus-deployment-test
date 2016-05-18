#!/bin/bash

set -xe

# Get Puppet modules
cd /opt
rm -rfv *puppet*

git clone https://github.com/cnaf/ci-puppet-modules.git
git clone https://github.com/marcocaberletti/puppet.git

# Configure
puppet apply --modulepath=/opt/ci-puppet-modules/modules/:/opt/puppet/modules/:/etc/puppet/module/ /manifest.pp


## wait for PDP before start
set +e
start_ts=$(date +%s)
timeout=300
sleeped=0
while true; do
    (echo > /dev/tcp/$PDP_HOST/$PDP_PORT) >/dev/null 2>&1
    result=$?
    if [[ $result -eq 0 ]]; then
        end_ts=$(date +%s)
        echo "$PDP_HOST:$PDP_PORT is available after $((end_ts - start_ts)) seconds"
        break
    fi
    echo "Waiting for PDP"
    sleep 5

    sleeped=$((sleeped+5))
    if [ $sleeped -ge $timeout  ]; then
    	echo "Timeout!"
    	exit 1
	fi
done
set -e

# Run
pepdctl start

sleep 5

tail -f /var/log/argus/pepd/*.log