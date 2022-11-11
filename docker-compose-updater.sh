#!/bin/bash
#
# Description
# The sh file only works with an absolute path.
# Additionally, the repository must have a docker-compose.yml file,
# which will allow updating the application based on docker compose.
# The repository must be public.
#
# How to use
# Usage: {path}/docker-compose-updater.sh {github_username}/{github_repository}
# Example: /var/docker-compose-updater.sh fabian/repository-example
#

# Get latest version
get_latest_release() {
    GITHUB_REPO="$1"
    curl --silent "https://api.github.com/repos/$GITHUB_REPO/releases/latest" |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/'
}

# Download a new realease
download_release_file() {
    GITHUB_REPO="$1"
    TMP_DIR="$2"
    ZIP_FILE="$TMP_DIR/$3.zip"
    curl -Ls --location --request GET https://api.github.com/repos/"$GITHUB_REPO"/releases/latest |
        jq -r ".zipball_url" |
        wget -qi - -O "$ZIP_FILE" &&
        unzip -q -o "$ZIP_FILE" -d "$TMP_DIR" &&
        cp -R "$TMP_DIR"/"$(unzip -Z -1 "$ZIP_FILE" | head -1)"/* "$TMP_DIR" &&
        rm -R "${TMP_DIR:?}/$(unzip -Z -1 "$ZIP_FILE" | head -1)/" &&
        rm "$ZIP_FILE"
}

# Function check exists directory
checkExitsDirectory() {
    directory="$1"
    retval=""
    if [[ -d "$directory" ]]; then
        retval="true"
    else
        retval="false"
    fi
    echo $retval
}

GITHUB_REPOSITORY="$1"
DEPLOYMENT_DIR="$1"
TMP=$(cat "$DEPLOYMENT_DIR"/LATEST_VERSION.txt 2>/dev/null || true)
CURRENT_VERSION="${TMP:-0.0.0}"
LATEST_VERSION=$(get_latest_release "$GITHUB_REPOSITORY")

# Check is a new version to deploy
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    if [ -e "$DEPLOYMENT_DIR" ]; then
        docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
    fi
    echo "Docker compose is already running the latest version ($LATEST_VERSION)"
else
    # Check connection to internet
    wget -q --spider http://google.com
    check_internet=$?
    if [ $check_internet -eq 0 ]; then

        echo "Docker compose is running an old version (current: $CURRENT_VERSION, latest: $LATEST_VERSION)"

        # Download the latest release's files
        TMP_DIR=$(mktemp -d -t docker-compose-XXXXXXXXXX)
        echo "$TMP_DIR"
        download_release_file "$GITHUB_REPOSITORY" "$TMP_DIR" "$LATEST_VERSION"

        # Copy previous deployment
        is_exists_directory_repository=$(checkExitsDirectory "$DEPLOYMENT_DIR")
        if [[ $is_exists_directory_repository == 'true' ]]; then
            # cp -R "$DEPLOYMENT_DIR" "$(echo "$DEPLOYMENT_DIR" | rev | cut -d'/' -f2- | rev)/$(basename "$DEPLOYMENT_DIR")-old_deploy"
            cp -R "$DEPLOYMENT_DIR" "$DEPLOYMENT_DIR-old_deploy"
        fi

        # Stop the current deployment
        if [ -e "$DEPLOYMENT_DIR" ]; then
            docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml down
        else
            mkdir -p "$DEPLOYMENT_DIR"
        fi

        # Delete the current deployment
        rm -rf "${DEPLOYMENT_DIR:?}/"*
        mv "$TMP_DIR"/* "$DEPLOYMENT_DIR"

        # Deploy the application
        docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d

        exit_code=$?
        if [ $exit_code -eq 0 ]; then
            echo "Successfully deploy latest"
            # Store the latest version and remove temporary files
            echo "$LATEST_VERSION" >"$DEPLOYMENT_DIR"/LATEST_VERSION.txt
            echo "Docker compose is now running version ${LATEST_VERSION}"

            # Remove copy temporal previus version
            is_exists_previous_version=$(checkExitsDirectory "$DEPLOYMENT_DIR-old_deploy")
            if [[ $is_exists_previous_version == 'true' ]]; then
                name_folder_old="$DEPLOYMENT_DIR-old_deploy"
                echo "$name_folder_old"
                rm -rf "${name_folder_old:?}"
            fi
        else
            # Delete the latest deployment with error
            rm -rf "${DEPLOYMENT_DIR:?}/"*

            # Rename previous version
            mv "$DEPLOYMENT_DIR-old_deploy" "$DEPLOYMENT_DIR"

            # Deploy previous version
            docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml down
        fi
    else
        docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
    fi
fi
