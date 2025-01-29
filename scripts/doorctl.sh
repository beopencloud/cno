#!/bin/bash

export VERIFY_CHECKSUM=0
export ALIAS=""
export OWNER=beopencloud
export REPO=cno
export SUCCESS_CMD="Use doorctl --help for more information"
export BINLOCATION="/usr/local/bin"

###############################
# Content common across repos #
###############################

version=$(curl -sI https://github.com/$OWNER/$REPO/releases/latest | grep -i "location:" | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')
echo "Vesrion $version"
if [ ! $version ]; then
    echo "Failed while attempting to install $REPO. Please manually install:"
    echo ""
    echo "1. Open your web browser and go to https://github.com/$OWNER/$REPO/releases"
    echo "2. Download the latest release for your platform. Call it 'doorctl'."
    echo "3. chmod +x ./doorctl"
    echo "4. mv ./doorctl $BINLOCATION"
    exit 1
fi

hasCli() {

    hasCurl=$(which curl)
    if [ "$?" = "1" ]; then
        echo "You need curl to use this script."
        exit 1
    fi
}

checkHash(){

    sha_cmd="sha256sum"

    if [ ! -x "$(command -v $sha_cmd)" ]; then
    sha_cmd="shasum -a 256"
    fi

    if [ -x "$(command -v $sha_cmd)" ]; then

    targetFileDir=${targetFile%/*}

    (cd $targetFileDir && curl -sSL $url.sha256|$sha_cmd -c >/dev/null)
   
        if [ "$?" != "0" ]; then
            rm $targetFile
            echo "Binary checksum didn't match. Exiting"
            exit 1
        fi   
    fi
}

getPackage() {
    uname=$(uname)
    userid=$(id -u)

    suffix=""
    case $uname in
    "Darwin")
    suffix="_Darwin_x86_64"
    ;;
    "Linux")
        arch=$(uname -m)
        echo $arch
        suffix="_Linux_x86_64"
    ;;
    esac

#    versionWithoutV=$(echo "$version" | tr v _)    
    targetFile="$(pwd)/doorctl${version}${suffix}.tar.gz"

    url=https://github.com/$OWNER/$REPO/releases/download/$version/doorctl${suffix}.tar.gz
    echo "Downloading package $url as $targetFile"

    curl -sSL $url --output "$targetFile"

    if [ "$?" = "0" ]; then

        if [ "$VERIFY_CHECKSUM" = "1" ]; then
            checkHash
        fi

    tar -xzf "$targetFile"
    chmod +x "$(pwd)/doorctl"
    rm $targetFile

    echo "Download complete."       
    if [ ! -w "$BINLOCATION" ]; then

            echo
            echo "============================================================"
            echo "  The script was run as a user who is unable to write"
            echo "  to $BINLOCATION. To complete the installation the"
            echo "  following commands may need to be run manually."
            echo "============================================================"
            echo
            echo "  sudo cp $(pwd)/doorctl $BINLOCATION/doorctl"      
            echo

        else

            echo
            echo "Running with sufficient permissions to attempt to move doorctl to $BINLOCATION"

            if [ ! -w "$BINLOCATION/doorctl" ] && [ -f "$BINLOCATION/doorctl" ]; then

            echo
            echo "================================================================"
            echo "  $BINLOCATION already exists and is not writeable"
            echo "  by the current user.  Please adjust the binary ownership"
            echo "  or run sh/bash with sudo." 
            echo "================================================================"
            echo
            exit 1

            fi

            mv "$(pwd)/doorctl" $BINLOCATION/doorctl
        
            if [ "$?" = "0" ]; then
                echo "New version of doorctl installed to $BINLOCATION"
            fi

            if [ -e "$(pwd)/doorctl" ]; then
                echo "$(pwd)/doorctl"
            fi


            echo ${SUCCESS_CMD}
        fi
    fi
}

hasCli
getPackage
