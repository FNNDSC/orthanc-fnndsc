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

while getopts "r:h:" opt; do
    case $opt in 
        r) b_restart=1
           RESTART=$OPTARG      ;;
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
    "orthanc-plugins"
)

title -d 1 "Using <$CREPO> containers..."
if [[ $CREPO == "fnndsc" ]] ; then
    echo "Pulling latest version of all containers..."
    for CONTAINER in ${A_CONTAINER[@]} ; do
        echo ""
        CMD="docker pull ${CREPO}/$CONTAINER"
        echo -e "\t\t\t${White}$CMD${NC}"
        echo $sep
        echo $CMD | sh
        echo $sep
    done
fi
windowBottom

if (( b_restart )) ; then
    docker-compose stop ${RESTART}_service && docker compose rm -f ${RESTART}_service
    docker-compose run --service-ports ${RESTART}_service
else
    title -d 1 "Using <$CREPO> family containers..."
    if (( ! b_skipIntro )) ; then 
        if [[ $CREPO == "fnndsc" ]] ; then
            echo "Pulling latest version of all containers..."
            for CONTAINER in ${A_CONTAINER[@]} ; do
                echo ""
                CMD="docker pull ${CREPO}/$CONTAINER"
                echo -e "\t\t\t${White}$CMD${NC}"
                echo $sep
                echo $CMD | sh
                echo $sep
            done
        fi
    fi
    windowBottom

    if (( ! b_skipIntro )) ; then 
        title -d 1 "Will use containers with following version info:"
        for CONTAINER in ${A_CONTAINER[@]} ; do
            if [[   $CONTAINER != "chris_dev_backend"    && \
                    $CONTAINER != "chris_store"          && \
                    $CONTAINER != "pl-pacsretrieve"      && \
                    $CONTAINER != "pl-pacsquery"         && \
                    $CONTAINER != "docker-swift-onlyone" && \
                    $CONTAINER != "swarm" ]] ; then
                CMD="docker run ${CREPO}/$CONTAINER --version"
                printf "${White}%40s\t\t" "${CREPO}/$CONTAINER"
                Ver=$(echo $CMD | sh | grep Version)
                echo -e "$Green$Ver"
            fi
        done
    fi

    title -d 1 "Shutting down any running Orthanc containers... "
    docker-compose stop
    docker-compose rm -vf
    for CONTAINER in ${A_CONTAINER[@]} ; do
        printf "%30s" "$CONTAINER"
        docker ps -a                                                        |\
            grep $CONTAINER                                                 |\
            awk '{printf("docker stop %s && docker rm -vf %s\n", $1, $1);}' |\
            sh >/dev/null
        printf "${Green}%20s${NC}\n" "done"
    done
    windowBottom

    declare -i b_localhost    
    title -d 1 "Checking current listener IP..."
    CLISTENER=$(cat orthanc.json | grep chips)
    printf "\nCurrent listener is \n\t\t$CLISTENER\n\n"

    if (( b_host )) ; then
        title -d 1 "Setting IP of listener in orthanc.json to $LISTENER..."
        cat orthanc.json | sed "s/localhost/$LISTENER/" > orthanc.host.json
        mv orthanc.json orthanc.json.orig
        mv orthanc.host.json orthanc.json
        CLISTENER=$(cat orthanc.json | grep chips)
        printf "${Yellow}\nCurrent listener reset to\n${LightGreen}\t\t$CLISTENER\n\n"
        windowBottom
    fi

    CLISTENER=$(cat orthanc.json | grep chips)
    b_localhost=$(echo "$CLISTENER" | grep -i localhost | wc -l)
    if (( b_localhost )) ; then
        printf "${LightRed}\tWARNING! The listener IP  is currently 'localhost'!\n"
        printf "${LightRed}\tOrthanc will PUSH DICOMs to 'localhost' i.e. *this*\n" 
        printf "${LightRed}\tcontainer as it exists in the network space.\n"
        printf "${LightRed}\tTHIS IS PROBABLY NOT WHAT YOU WANT.\n\n"
        printf "${Yellow}\tPlease enter the IP of the listener host: "
        printf "${LightGreen}"
        read LISTENER
        b_host=1
        if (( b_host )) ; then
            title -d 1 "Setting IP of listener in orthanc.json to $LISTENER..."
            cat orthanc.json | sed "s/localhost/$LISTENER/" > orthanc.host.json
            mv orthanc.json orthanc.json.orig
            mv orthanc.host.json orthanc.json
            CLISTENER=$(cat orthanc.json | grep chips)
            printf "${Yellow}\nCurrent listener reset to\n${LightGreen}\t\t$CLISTENER\n\n"
            windowBottom
        fi
    fi 

    title -d 1 "Starting Orthanc environment using " " ./docker-compose.yml"
    # export HOST_IP=$(ip route | grep -v docker | awk '{if(NF==11) print $9}')
    # echo "Exporting HOST_IP=$HOST_IP as environment var..."
    echo "docker-compose up" | sh -v
    windowBottom
fi
