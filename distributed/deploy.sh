#!/bin/bash

set -xe

PLATFORM="${PLATFORM:-el7}"
TESTSUITE_BRANCH="${TESTSUITE_BRANCH:-master}"

netname="argus"$PLATFORM"_default"
testdir="$PWD/argus-$PLATFORM"
pdp_admin_passwd="pdpadmin_password"
pap_host="argus-pap-$PLATFORM.cnaf.test"
pdp_host="argus-pdp-$PLATFORM.cnaf.test"
pep_host="argus-pep-$PLATFORM.cnaf.test"

DOCKER_NET_NAME="${DOCKER_NET_NAME:-$netname}"

if [ ! `which docker-compose` ]; then
	curl -L https://github.com/docker/compose/releases/download/1.7.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
fi

## Run Argus service in detached mode
docker-compose -f $testdir/docker-compose.yml up --build -d

## Get testsuite
tmpdir="/tmp/tester_$$/argus-robot-testsuite"
git clone https://github.com/marcocaberletti/argus-robot-testsuite.git $tmpdir
cd $tmpdir
git checkout $TESTSUITE_BRANCH
cd $tmpdir/docker
sh build-image.sh

docker run --net=$DOCKER_NET_NAME \
	-e T_PDP_ADMIN_PASSWORD=$pdp_admin_passwd \
	-e PAP_HOST=$pap_host \
	-e PDP_HOST=$pdp_host \
	-e PEP_HOST=$pep_host \
	-e TESTSUITE_BRANCH=$TESTSUITE_BRANCH \
	italiangrid/argus-testsuite:latest

docker-compose -f $testdir/docker-compose.yml stop


