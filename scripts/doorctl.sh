#!/bin/bash

NEW_SCRIPT_URL="https://raw.githubusercontent.com/doorcloud/door/main/scripts/doorctl.sh"

warn() {
    echo >&2 ""
    echo >&2 "============================================================"
    echo >&2 "  DEPRECATION NOTICE"
    echo >&2 ""
    echo >&2 "  This installer is deprecated."
    echo >&2 "  New doorctl releases are published from doorcloud/door."
    echo >&2 ""
    echo >&2 "  Switch to the new installer:"
    echo >&2 "    curl -sSL https://raw.githubusercontent.com/doorcloud/door/main/scripts/doorctl.sh | sh -s"
    echo >&2 ""
    echo >&2 "  Alternative install channels:"
    echo >&2 "    Homebrew:  brew install doorcloud/door/doorctl"
    echo >&2 "    Releases:  https://github.com/doorcloud/door/releases"
    echo >&2 "    Helm repo: https://doorcloud.github.io/door"
    echo >&2 "============================================================"
    echo >&2 ""
}

warn

# Try to delegate to the new installer. If the download fails, fall back
# to the legacy logic so the script keeps working on offline/filtered networks.
tmp_script=""
if command -v curl >/dev/null 2>&1 && command -v mktemp >/dev/null 2>&1; then
    tmp_script=$(mktemp /tmp/doorctl-install.XXXXXX 2>/dev/null || true)
    if [ -n "$tmp_script" ] && curl -fsSL --max-time 30 "$NEW_SCRIPT_URL" -o "$tmp_script" 2>/dev/null; then
        if head -n 1 "$tmp_script" | grep -q '^#!.*sh'; then
            chmod +x "$tmp_script"
            exec "$tmp_script" "$@"
        fi
    fi
fi

# Cleanup and fall back to the legacy path
if [ -n "$tmp_script" ] && [ -f "$tmp_script" ]; then
    rm -f "$tmp_script" 2>/dev/null || true
fi

echo >&2 ""
echo >&2 "Warning: could not fetch the new installer from $NEW_SCRIPT_URL."
echo >&2 "Falling back to the legacy install path. Consider migrating to:"
echo >&2 "  https://github.com/doorcloud/door"
echo >&2 ""

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
