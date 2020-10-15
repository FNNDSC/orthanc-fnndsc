#!/bin/bash
#
# NAME
#
#   make
#
# SYNPOSIS
#
#   make [-h <IP>]
#
# DESC
#
#   'make' is the main entry point for instantiating an FNNDSC orthanc
#   complete backend dev environment.
#
# ARGS
#
#  [-h <IP>]
#
#       If specified set the IP of the listener to which orthanc will push
#       images.
#
#

source ./decorate.sh
source ./cparse.sh

while getopts "h:" opt; do
    case $opt in
        h) b_host=1
           LISTENER=$OPTARG     ;;
    esac
done
shift $(($OPTIND - 1))

CREPO=jodogne
if (( $# == 1 )) ; then
    CREPO=$1
fi
export CREPO=$CREPO

declare -a A_CONTAINER=(
    "jodogne/orthanc-plugins"
)

title -d 1 "Pulling non-'local/' core containers where needed..."   \
            "and creating appropriate .env for docker-compose"
echo "# Variables declared here are available to"               > .env
echo "# docker-compose on execution"                            >>.env
for CORE in ${A_CONTAINER[@]} ; do
    cparse $CORE " " "REPO" "CONTAINER" "MMN" "ENV"
    echo "${ENV}=${REPO}"                                       >>.env
    if [[ $REPO != "local" ]] ; then
        echo ""                                                 | ./boxes.sh
        CMD="docker pull ${REPO}/$CONTAINER"
        printf "${LightCyan}%-40s${Green}%40s${Yellow}\n"       \
                    "docker pull" "${REPO}/$CONTAINER"          | ./boxes.sh
        windowBottom
        sleep 1
        echo $CMD | sh                                          | ./boxes.sh -c
    fi
done
echo "TAG="                                                     >>.env
windowBottom


title -d 1 "Shutting down any running orthanc and orthanc related containers... "
    echo "This might take a few minutes... please be patient."              | ./boxes.sh ${Yellow}
    windowBottom
    docker-compose --no-ansi -f docker-compose.yml stop >& dc.out > /dev/null
    echo -en "\033[2A\033[2K"
    cat dc.out | sed -E 's/(.{80})/\1\n/g'                                  | ./boxes.sh ${LightBlue}
    docker-compose --no-ansi -f docker-compose.yml rm -vf >& dc.out > /dev/null
    cat dc.out | sed -E 's/(.{80})/\1\n/g'                                  | ./boxes.sh ${LightCyan}
    for CORE in ${A_CONTAINER[@]} ; do
        cparse $CORE " " "REPO" "CONTAINER" "MMN" "ENV"
        docker ps -a                                                        |\
            grep $CONTAINER                                                 |\
            awk '{printf("docker stop %s && docker rm -vf %s\n", $1, $1);}' |\
            sh >/dev/null                                                   | ./boxes.sh
        printf "${White}%40s${Green}%40s${NC}\n"                            \
                    "$CONTAINER" "stopped"                                  | ./boxes.sh
    done
windowBottom

declare -i b_localhost
title -d 1 "Checking current listener IP..."
cat orthanc.json | grep chips                                               >& dc.out 2>/dev/null
echo "Current listener is"                                                  | ./boxes.sh
cat dc.out                                                                  | ./boxes.sh ${LightGreen}
echo ""                                                                     | ./boxes.sh
windowBottom


if (( b_host )) ; then
    title -d 1 "Setting IP of listener in orthanc.json to $LISTENER..."
    cat orthanc.json | sed "s/localhost/$LISTENER/" > orthanc.host.json
    mv orthanc.json orthanc.json.orig
    mv orthanc.host.json orthanc.json
    cat orthanc.json | grep chips                                           >& dc.out 2>/dev/null
    echo "New listener set to"                                              | ./boxes.sh
    cat dc.out                                                              | ./boxes.sh ${LightGreen}
    echo ""                                                                 | ./boxes.sh
    windowBottom
fi

CLISTENER=$(cat orthanc.json | grep chips)
b_localhost=$(echo "$CLISTENER" | grep -i localhost | wc -l)
if (( b_localhost )) ; then
    echo "WARNING!"                                                         | ./boxes.sh ${LightRed}
    echo "The listener IP is currently set to  'localhost', which"          | ./boxes.sh ${LightRed}
    echo "means that Orthanc will PUSH DICOMs to *this* container"          | ./boxes.sh ${LightRed}
    echo "and not the probable destination where a listener has "           | ./boxes.sh ${LightRed}
    echo "been setup to receive DICOM transmission."                        | ./boxes.sh ${LightRed}
    echo ""                                                                 | ./boxes.sh
    echo "          THIS IS PROBABLY NOT WHAT YOU WANT."                    | ./boxes.sh ${LightRed}
    echo ""                                                                 | ./boxes.sh
    echo "Please enter the IP of the listener host: "                       | ./boxes.sh ${Yellow}
    echo ""                                                                 | ./boxes.sh
    windowBottom
    old_stty_cfg=$(stty -g)
    stty raw -echo ; LISTENER=$(head -c 1) ; stty $old_stty_cfg
    echo -en "\033[2A\033[2K"
    read LISTENER
    b_host=1
    if (( b_host )) ; then
        cat orthanc.json | sed "s/localhost/$LISTENER/" > orthanc.host.json
        mv orthanc.json orthanc.json.orig
        mv orthanc.host.json orthanc.json
        cat orthanc.json | grep chips                                           >& dc.out 2>/dev/null
        echo "New listener set to"                                              | ./boxes.sh
        cat dc.out                                                              | ./boxes.sh ${LightGreen}
        echo ""                                                                 | ./boxes.sh
        windowBottom
    fi
fi

title -d 1 "Starting Orthanc environment using " " ./docker-compose.yml"
printf "${LightCyan}%40s${LightGreen}%40s\n"                \
            "Starting in interactive mode" "chris_dev"      | ./boxes.sh
windowBottom
docker-compose -f docker-compose.yml run --service-ports chris_orthanc_db

if (( $? == "1" )) ; then
    echo ""
    title -d 1 "Error detected!"
    echo ""                                                                 | ./boxes.sh ${LightRed}
    echo "WARNING!"                                                         | ./boxes.sh ${LightRed}
    echo ""                                                                 | ./boxes.sh ${LightRed}
    echo "Some error seems to have occurred in starting this service."      | ./boxes.sh ${LightRed}
    echo "If there is an error about "                                      | ./boxes.sh ${LightRed}
    echo ""                                                                 | ./boxes.sh ${LightRed}
    echo "   \"listen tcp 0.0.0.0:8042: bind: address already in use\""     | ./boxes.sh ${LightYellow}
    echo ""                                                                 | ./boxes.sh ${LightRed}
    echo "then please check that no service is listening on that"           | ./boxes.sh ${LightGreen}
    echo "port. Note that if you have installed the neurodebian tools"      | ./boxes.sh ${LightGreen}
    echo "you may have a native orthanc already listening on port"          | ./boxes.sh ${LightGreen}
    echo "8042. Either change the portmapping for this container"           | ./boxes.sh ${LightGreen}
    echo "or shut down whatever might be listening on port 8042."           | ./boxes.sh ${LightGreen}
    echo ""                                                                 | ./boxes.sh ${LightGreen}
    windowBottom
fi
