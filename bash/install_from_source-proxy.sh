#!/bin/bash
#   Copyright 2016 Telefónica Investigación y Desarrollo S.A.U.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

function usage(){
    echo -e "usage: $0 [OPTIONS]"
    echo -e "Install OSM from source"
    echo -e "  OPTIONS"
    echo -e "     --uninstall:   uninstall OSM: remove the containers and delete NAT rules"
    echo -e "     -b <refspec>:  install OSM from source code using a specific branch (master, v2.0, ...) or tag"
    echo -e "                    -b master          (main dev branch)"
    echo -e "                    -b v2.0            (v2.0 branch)"
    echo -e "                    -b tags/v1.1.0     (a specific tag)"
    echo -e "                    ..."
    echo -e "     --develop:     (deprecated, use '-b master') install OSM from source code using the master branch"
    echo -e "     --nat:         install only NAT rules"
#    echo -e "     --update:      update to the latest stable release or to the latest commit if using a specific branch"
    echo -e "     --showopts:    print chosen options and exit (only for debugging)"
    echo -e "     -y:            do not prompt for confirmation, assumes yes"
    echo -e "     -h / --help:   print this help"
}

#Uninstall OSM: remove containers
function uninstall(){
    echo -e "\nUninstalling OSM"
    if [ $RC_CLONE ] || [ -n "$TEST_INSTALLER" ]; then
        $OSM_DEVOPS/jenkins/host/clean_container RO
        $OSM_DEVOPS/jenkins/host/clean_container VCA
        $OSM_DEVOPS/jenkins/host/clean_container SO
        #$OSM_DEVOPS/jenkins/host/clean_container UI
    else
        lxc stop RO && lxc delete RO
        lxc stop VCA && lxc delete VCA
        lxc stop SO-ub && lxc delete SO-ub
    fi
}

#Configure NAT rules, based on the current IP addresses of containers
function nat(){
    echo -e "\nChecking required packages: iptables-persistent"
    dpkg -l iptables-persistent &>/dev/null || ! echo -e "    Not installed.\nInstalling iptables-persistent requires root privileges" || \
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install iptables-persistent
    echo -e "\nConfiguring NAT rules"
    echo -e "   Required root privileges"
    sudo $OSM_DEVOPS/installers/nat_osm
}

#Update RO, SO and UI:
function update(){
    echo -e "\nUpdating components"

    echo -e "     Updating RO"
    CONTAINER="RO"
    MDG="RO"
    INSTALL_FOLDER="/opt/openmano"
    echo -e "     Fetching the repo"
    lxc exec $CONTAINER -- git -C $INSTALL_FOLDER fetch --all
    BRANCH=""
    BRANCH=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER status -sb | head -n1 | sed -n 's/^## \(.*\).*/\1/p'|awk '{print $1}' |sed 's/\(.*\)\.\.\..*/\1/'`
    [ -z "$BRANCH" ] && FATAL "Could not find the current branch in use in the '$MDG'"
    CURRENT=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER status |head -n1`
    CURRENT_COMMIT_ID=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER rev-parse HEAD`
    echo "         FROM: $CURRENT ($CURRENT_COMMIT_ID)"
    # COMMIT_ID either was  previously set with -b option, or is an empty string
    CHECKOUT_ID=$COMMIT_ID
    [ -z "$CHECKOUT_ID" ] && [ "$BRANCH" == "HEAD" ] && CHECKOUT_ID="tags/$LATEST_STABLE_DEVOPS"
    [ -z "$CHECKOUT_ID" ] && [ "$BRANCH" != "HEAD" ] && CHECKOUT_ID="$BRANCH"
    if [[ $CHECKOUT_ID == "tags/"* ]]; then
        REMOTE_COMMIT_ID=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER rev-list -n 1 $CHECKOUT_ID`
    else
        REMOTE_COMMIT_ID=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER rev-parse origin/$CHECKOUT_ID`
    fi
    echo "         TO: $CHECKOUT_ID ($REMOTE_COMMIT_ID)"
    if [ "$CURRENT_COMMIT_ID" == "$REMOTE_COMMIT_ID" ]; then
        echo "         Nothing to be done."
    else
        echo "         Update required."
        lxc exec $CONTAINER -- service osm-ro stop
        lxc exec $CONTAINER -- git -C /opt/openmano stash
        lxc exec $CONTAINER -- git -C /opt/openmano pull --rebase
        lxc exec $CONTAINER -- git -C /opt/openmano checkout $CHECKOUT_ID
        lxc exec $CONTAINER -- git -C /opt/openmano stash pop
        lxc exec $CONTAINER -- /opt/openmano/database_utils/migrate_mano_db.sh
        lxc exec $CONTAINER -- service osm-ro start
    fi
    echo

    echo -e "     Updating SO and UI"
    CONTAINER="SO-ub"
    MDG="SO"
    INSTALL_FOLDER=""   # To be filled in
    echo -e "     Fetching the repo"
    lxc exec $CONTAINER -- git -C $INSTALL_FOLDER fetch --all
    BRANCH=""
    BRANCH=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER status -sb | head -n1 | sed -n 's/^## \(.*\).*/\1/p'|awk '{print $1}' |sed 's/\(.*\)\.\.\..*/\1/'`
    [ -z "$BRANCH" ] && FATAL "Could not find the current branch in use in the '$MDG'"
    CURRENT=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER status |head -n1`
    CURRENT_COMMIT_ID=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER rev-parse HEAD`
    echo "         FROM: $CURRENT ($CURRENT_COMMIT_ID)"
    # COMMIT_ID either was  previously set with -b option, or is an empty string
    CHECKOUT_ID=$COMMIT_ID
    [ -z "$CHECKOUT_ID" ] && [ "$BRANCH" == "HEAD" ] && CHECKOUT_ID="tags/$LATEST_STABLE_DEVOPS"
    [ -z "$CHECKOUT_ID" ] && [ "$BRANCH" != "HEAD" ] && CHECKOUT_ID="$BRANCH"
    if [[ $CHECKOUT_ID == "tags/"* ]]; then
        REMOTE_COMMIT_ID=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER rev-list -n 1 $CHECKOUT_ID`
    else
        REMOTE_COMMIT_ID=`lxc exec $CONTAINER -- git -C $INSTALL_FOLDER rev-parse origin/$CHECKOUT_ID`
    fi
    echo "         TO: $CHECKOUT_ID ($REMOTE_COMMIT_ID)"
    if [ "$CURRENT_COMMIT_ID" == "$REMOTE_COMMIT_ID" ]; then
        echo "         Nothing to be done."
    else
        echo "         Update required."
        # Instructions to be added
        # lxc exec SO-ub -- ...
    fi
    echo
}

#Configure VCA, SO and RO with the initial configuration:
#  RO -> tenant:osm, logs to be sent to SO
#  VCA -> juju-password
#  SO -> route to Juju Controller, add RO account, add VCA account
function configure(){
    #Configure components
    echo -e "\nConfiguring components"
    . $OSM_DEVOPS/installers/export_ips

    echo -e "       Configuring RO"
    lxc exec RO -- sed -i -e "s/^\#\?log_socket_host:.*/log_socket_host: $SO_CONTAINER_IP/g" /etc/osm/openmanod.cfg
    lxc exec RO -- service osm-ro restart
    time=0; step=2; timelength=20; while [ $time -le $timelength ]; do sleep $step; echo -n "."; time=$((time+step)); done; echo
    lxc exec RO -- openmano tenant-delete -f osm >/dev/null
    RO_TENANT_ID=`lxc exec RO -- openmano tenant-create osm |awk '{print $1}'`

    echo -e "       Configuring VCA"
    JUJU_PASSWD=`date +%s | sha256sum | base64 | head -c 32`
    echo -e "$JUJU_PASSWD\n$JUJU_PASSWD" | lxc exec VCA -- juju change-user-password
    JUJU_CONTROLLER_IP=`lxc exec VCA -- lxc list -c 4 |grep eth0 |awk '{print $2}'`

    echo -e "       Configuring SO"
    sudo route add -host $JUJU_CONTROLLER_IP gw $VCA_CONTAINER_IP
    sudo sed -i "$ i route add -host $JUJU_CONTROLLER_IP gw $VCA_CONTAINER_IP" /etc/rc.local
    lxc exec SO-ub -- nohup sudo -b -H /usr/rift/rift-shell -r -i /usr/rift -a /usr/rift/.artifacts -- ./demos/launchpad.py --use-xml-mode &
    time=0; step=30; timelength=300; while [ $time -le $timelength ]; do sleep $step; echo -n "."; time=$((time+step)); done; echo

    curl -k --request POST \
      --url https://$SO_CONTAINER_IP:8008/api/config/config-agent \
      --header 'accept: application/vnd.yang.data+json' \
      --header 'authorization: Basic YWRtaW46YWRtaW4=' \
      --header 'cache-control: no-cache' \
      --header 'content-type: application/vnd.yang.data+json' \
      --data '{"account": [ { "name": "osmjuju", "account-type": "juju", "juju": { "ip-address": "'$JUJU_CONTROLLER_IP'", "port": "17070", "user": "admin", "secret": "'$JUJU_PASSWD'" }  }  ]}'

    curl -k --request PUT \
      --url https://$SO_CONTAINER_IP:8008/api/config/resource-orchestrator \
      --header 'accept: application/vnd.yang.data+json' \
      --header 'authorization: Basic YWRtaW46YWRtaW4=' \
      --header 'cache-control: no-cache' \
      --header 'content-type: application/vnd.yang.data+json' \
      --data '{ "openmano": { "host": "'$RO_CONTAINER_IP'", "port": "9090", "tenant-id": "'$RO_TENANT_ID'" }, "name": "osmopenmano", "account-type": "openmano" }'

}

function install_lxd() {
    lxd init --auto
    lxd waitready
    systemctl stop lxd-bridge
    systemctl --system daemon-reload
    systemctl enable lxd-bridge
    systemctl start lxd-bridge
}


UNINSTALL=""
DEVELOP=""
NAT=""
UPDATE=""
RECONFIGURE=""
TEST_INSTALLER=""
LXD=""
SHOWOPTS=""
COMMIT_ID="v2.0.2-proxy"
ASSUME_YES=""
INSTALL_FROM_SOURCE="y"

while getopts ":hy-:b:" o; do
    case "${o}" in
        h)
            usage && exit 0
            ;;
        b)
            COMMIT_ID=${OPTARG}
            ;;
        -)
            [ "${OPTARG}" == "help" ] && usage && exit 0
            [ "${OPTARG}" == "source" ] && INSTALL_FROM_SOURCE="y" && continue
            [ "${OPTARG}" == "develop" ] && DEVELOP="y" && continue
            [ "${OPTARG}" == "uninstall" ] && UNINSTALL="y" && continue
            [ "${OPTARG}" == "nat" ] && NAT="y" && continue
            [ "${OPTARG}" == "update" ] && UPDATE="y" && continue
            [ "${OPTARG}" == "reconfigure" ] && RECONFIGURE="y" && continue
            [ "${OPTARG}" == "test" ] && TEST_INSTALLER="y" && continue
            [ "${OPTARG}" == "lxd" ] && LXD="y" && continue
            [ "${OPTARG}" == "showopts" ] && SHOWOPTS="y" && continue
            echo -e "Invalid option: '--$OPTARG'\n" >&2
            usage && exit 1
            ;;
        \?)
            echo -e "Invalid option: '-$OPTARG'\n" >&2
            usage && exit 1
            ;;
        y)
            ASSUME_YES="y"
            ;;
        *)
            usage && exit 1
            ;;
    esac
done

if [ -n "$SHOWOPTS" ]; then
    echo "DEVELOP=$DEVELOP"
    echo "INSTALL_FROM_SOURCE=$INSTALL_FROM_SOURCE"
    echo "UNINSTALL=$UNINSTALL"
    echo "NAT=$NAT"
    echo "UPDATE=$UPDATE"
    echo "RECONFIGURE=$RECONFIGURE"
    echo "TEST_INSTALLER=$TEST_INSTALLER"
    echo "LXD=$LXD"
    echo "SHOWOPTS=$SHOWOPTS"
    echo "Install from specific refspec (-b): $COMMIT_ID"
    exit 0
fi

[ -z "$COMMIT_ID" ] && [ -n "$DEVELOP" ] && COMMIT_ID="master"
[ -n "$COMMIT_ID" ] && INSTALL_FROM_SOURCE="y"

if [ -n "$TEST_INSTALLER" ]; then
    echo -e "\nUsing local devops repo for OSM installation"
    TEMPDIR="$(dirname $(realpath $(dirname $0)))"
else
    echo -e "\nCreating temporary dir for OSM installation"
    TEMPDIR="$(mktemp -d -q --tmpdir "installosm.XXXXXX")"
    trap 'rm -rf "$TEMPDIR"' EXIT
fi

echo -e "Checking required packages: git"
dpkg -l git &>/dev/null || ! echo -e "     git not installed.\nInstalling git requires root privileges" || sudo apt-get install -y git
if [ -z "$TEST_INSTALLER" ]; then
    echo -e "\nCloning devops repo temporarily"
    git clone https://github.com/igordcard/devops.git $TEMPDIR
    RC_CLONE=$?
fi

echo -e "\nGuessing the current stable release"
LATEST_STABLE_DEVOPS=`git -C $TEMPDIR tag -l v[0-9].* | tail -n1`
[ -z "$COMMIT_ID" ] && [ -z "$LATEST_STABLE_DEVOPS" ] && echo "Could not find the current latest stable release" && exit 0
echo "Latest tag in devops repo: $LATEST_STABLE_DEVOPS"
[ -z "$COMMIT_ID" ] && [ -n "$LATEST_STABLE_DEVOPS" ] && COMMIT_ID="tags/$LATEST_STABLE_DEVOPS"
[ -z "$TEST_INSTALLER" ] && git -C $TEMPDIR checkout tags/$LATEST_STABLE_DEVOPS

git -C $TEMPDIR checkout $COMMIT_ID

OSM_DEVOPS=$TEMPDIR
OSM_JENKINS="$TEMPDIR/jenkins"
. $OSM_JENKINS/common/all_funcs

[ -n "$UNINSTALL" ] && uninstall && echo -e "\nDONE" && exit 0
[ -n "$NAT" ] && nat && echo -e "\nDONE" && exit 0
[ -n "$UPDATE" ] && update && echo -e "\nDONE" && exit 0
[ -n "$RECONFIGURE" ] && configure && echo -e "\nDONE" && exit 0

#Installation starts here
echo -e "\nInstalling OSM from refspec: $COMMIT_ID"
if [ -n "$INSTALL_FROM_SOURCE" ] && [ -z "$ASSUME_YES" ]; then 
    read -e -p "The installation will take about 75-90 minutes. Continue (y/n)?" USER_CONFIRMATION
    [ -n "$USER_CONFIRMATION" ] && [ "$USER_CONFIRMATION" != "yes" ] && \
        [ "$USER_CONFIRMATION" != "y" ] && echo "Cancelled!" && exit 0
fi

echo -e "\nChecking required packages: wget, curl, tar"
dpkg -l wget curl tar &>/dev/null || ! echo -e "    One or several packages are not installed.\nInstalling required packages\n     Root privileges are required" || sudo apt-get install -y wget curl tar

echo -e "Checking required packages: lxd"
lxd --version &>/dev/null || FATAL "lxd not present, exiting."
[ -n "$LXD" ] && echo -e "\nConfiguring lxd" && install_lxd

wget -q -O- https://osm-download.etsi.org/ftp/osm-2.0-two/README.txt &> /dev/null

if [ -z "$INSTALL_FROM_SOURCE" ]; then
    echo -e "\nCreating the containers and installing from binaries ..."
    $OSM_DEVOPS/jenkins/host/install RO || FATAL "RO install failed"
    $OSM_DEVOPS/jenkins/host/start_build VCA || FATAL "VCA install failed"
    $OSM_DEVOPS/jenkins/host/install SO || FATAL "SO install failed"
    $OSM_DEVOPS/jenkins/host/install UI || FATAL "UI install failed"
else #install from source
    echo -e "\nCreating the containers and building from source ..."
    $OSM_DEVOPS/jenkins/host/start_build RO --notest checkout $COMMIT_ID || FATAL "RO container build failed (refspec: '$COMMIT_ID')"
    $OSM_DEVOPS/jenkins/host/start_build VCA || FATAL "VCA container build failed"
    $OSM_DEVOPS/jenkins/host/start_build SO checkout $COMMIT_ID || FATAL "SO container build failed (refspec: '$COMMIT_ID')"
    $OSM_DEVOPS/jenkins/host/start_build UI checkout $COMMIT_ID || FATAL "UI container build failed (refspec: '$COMMIT_ID')"
fi

#Install iptables-persistent and configure NAT rules
nat

#Configure components
configure

wget -q -O- https://osm-download.etsi.org/ftp/osm-2.0-two/README2.txt &> /dev/null
echo -e "\nDONE"
