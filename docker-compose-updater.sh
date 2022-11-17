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
logger -p local0.debug -it docker-compose-updater  "Start docker-compose-updater"
get_latest_release() {
    logger -p local0.debug -it docker-compose-updater  "start function get latest version"
    GITHUB_REPO="$1"
    logger -p local0.debug -it docker-compose-updater  "GitHub Repository = $1"
    logger -p local0.debug -it docker-compose-updater  "Get tag name parameter from repository"
    curl --silent "https://api.github.com/repos/$GITHUB_REPO/releases/latest" |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/'
    logger -p local0.debug -it docker-compose-updater  "End function get latest version"
}

# Download a new realease
download_release_file() {
    logger -p local0.debug -it docker-compose-updater  "start function download release file"
    GITHUB_REPO="$1"
    logger -p local0.debug -it docker-compose-updater  "GitHub Repository = $1"
    TMP_DIR="$2"
    logger -p local0.debug -it docker-compose-updater  "Temporal directory = $2"
    ZIP_FILE="$TMP_DIR/$3.zip"
    logger -p local0.debug -it docker-compose-updater  "zip file = $ZIP_FILE"

    curl -Ls --location --request GET https://api.github.com/repos/"$GITHUB_REPO"/releases/latest |
    logger -p local0.debug -it docker-compose-updater  "show git repository to extract and download info"
        logger -p local0.debug -it docker-compose-updater  "extract zipball_url parameter from github repository"
        jq -r ".zipball_url" |
        logger -p local0.debug -it docker-compose-updater  "download  $ZIP_FILE"
        wget -qi - -O "$ZIP_FILE" &&
        logger -p local0.debug -it docker-compose-updater  "extract  $ZIP_FILE in $TMP_DIR"
        unzip -q -o "$ZIP_FILE" -d "$TMP_DIR" &&
        logger -p local0.debug -it docker-compose-updater  "move files unziped and clean folders"
        cp -R "$TMP_DIR"/"$(unzip -Z -1 "$ZIP_FILE" | head -1)"/* "$TMP_DIR" &&
        rm -R "${TMP_DIR:?}/$(unzip -Z -1 "$ZIP_FILE" | head -1)/" &&
        rm "$ZIP_FILE"
    logger -p local0.debug -it docker-compose-updater  "end function download release file"
}

# Function check exists directory
checkExitsDirectory() {
    logger -p local0.debug -it docker-compose-updater  "start function check if exits directory"
    directory="$1"
    logger -p local0.debug -it docker-compose-updater  "directory to check = $directory"
    retval=""
    if [[ -d "$directory" ]]; then
        retval="true"
    else
        retval="false"
    fi
    echo $retval
    logger -p local0.debug -it docker-compose-updater  "directory exists?= $retval"
    logger -p local0.debug -it docker-compose-updater  "end function check if exists directory"
}

GITHUB_REPOSITORY="$1"
logger -p local0.debug -it docker-compose-updater  "GITHUB REPOSITORY = $1"
DEPLOYMENT_DIR="$1"
logger -p local0.debug -it docker-compose-updater  "DEPLOYMENT DIRECTORY = $1"
TMP=$(cat "$DEPLOYMENT_DIR"/LATEST_VERSION.txt 2>/dev/null || true)
logger -p local0.debug -it docker-compose-updater  "create temporal file= $TMP"
CURRENT_VERSION="${TMP:-0.0.0}"
logger -p local0.debug -it docker-compose-updater  "Current version= $CURRENT_VERSION"
LATEST_VERSION=$(get_latest_release "$GITHUB_REPOSITORY")
logger -p local0.debug -it docker-compose-updater  "Latest version= $LATEST_VERSION"

# Check is a new version to deploy
logger -p local0.debug -it docker-compose-updater  "Check is a new version to deploy"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    if [ -e "$DEPLOYMENT_DIR" ]; then
        docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
        logger -p local0.debug -it docker-compose-updater "docker compose start whit docker-compose.yml file"
    fi
    echo "Docker compose is already running the latest version ($LATEST_VERSION)"
    logger -p local0.debug -it docker-compose-updater  "Docker compose is already running the latest version $LATEST_VERSION"
else
    # Check connection to internet
    logger -p local0.debug -it docker-compose-updater "Check connection to internet"
    wget -q --spider http://google.com
    check_internet=$?
    logger -p local0.debug -it docker-compose-updater "check internet = $?"
    if [ $check_internet -eq 0 ]; then
        logger -p local0.debug -it docker-compose-updater "as the internet is available, update version"
        echo "Docker compose is running an old version (current: $CURRENT_VERSION, latest: $LATEST_VERSION)"
        logger -p local0.debug -it docker-compose-updater "Docker compose is running an old version (current: $CURRENT_VERSION, latest: $LATEST_VERSION)"
        # Download the latest release's files
        logger -p local0.debug -it docker-compose-updater "Download the latest relese's files"
        TMP_DIR=$(mktemp -d -t docker-compose-XXXXXXXXXX)
        echo "$TMP_DIR"
        logger -p local0.debug -it docker-compose-updater "Temporal directory = $TMP_DIR"
        download_release_file "$GITHUB_REPOSITORY" "$TMP_DIR" "$LATEST_VERSION"
        logger -p local0.debug -it docker-compose-updater "Use function download_relese_file with variables= $GITHUB_REPOSITORY , $TMP_DIR , $LATEST_VERSION"

        # Copy previous deployment
        logger -p local0.debug -it docker-compose-updater "Copy previous deployment"
        is_exists_directory_repository=$(checkExitsDirectory "$DEPLOYMENT_DIR")
        logger -p local0.debug -it docker-compose-updater "check if exist directory ($DEPLOYMENT_DIR) whit function checkExitsDirectory"
        logger -p local0.debug -it docker-compose-updater "Directory exist?= $is_exists_directory_repository"
        if [[ $is_exists_directory_repository == 'true' ]]; then
            logger -p local0.debug -it docker-compose-updater "As exists directory repository, clone directory with tag old-deploy"
            # cp -R "$DEPLOYMENT_DIR" "$(echo "$DEPLOYMENT_DIR" | rev | cut -d'/' -f2- | rev)/$(basename "$DEPLOYMENT_DIR")-old_deploy"
            cp -R "$DEPLOYMENT_DIR" "$DEPLOYMENT_DIR-old_deploy"
        fi

        # Stop the current deployment
        logger -p local0.debug -it docker-compose-updater "Stop the current deployment"
        if [ -e "$DEPLOYMENT_DIR" ]; then
            docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml down
            logger -p local0.debug -it docker-compose-updater "stop deployment with docker compose"
        else
            mkdir -p "$DEPLOYMENT_DIR"
            logger -p local0.debug -it docker-compose-updater "create directory = $DEPLOYMENT_DIR"
        fi

        # Delete the current deployment
        logger -p local0.debug -it docker-compose-updater "Delete the current deployment"
        rm -rf "${DEPLOYMENT_DIR:?}/"*
        logger -p local0.debug -it docker-compose-updater "Move temporal dir to deployment_dir"
        mv "$TMP_DIR"/* "$DEPLOYMENT_DIR"

        # Deploy the application
        docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
        logger -p local0.debug -it docker-compose-updater "Deploy the application using docker compose = (docker compose -f $DEPLOYMENT_DIR/docker-compose.yml up -d)"
        exit_code=$?
        logger -p local0.debug -it docker-compose-updater "exit code = $?"
        if [ $exit_code -eq 0 ]; then
            echo "Successfully deploy latest"
            logger -p local0.debug -it docker-compose-updater "Successfully deploy latest"
            # Store the latest version and remove temporary files
            logger -p local0.debug -it docker-compose-updater "Store the latest version and remove temporary files"
            echo "$LATEST_VERSION" >"$DEPLOYMENT_DIR"/LATEST_VERSION.txt
            logger -p local0.debug -it docker-compose-updater "Docker compose is now running version ${LATEST_VERSION}"
            echo "Docker compose is now running version ${LATEST_VERSION}"

            # Remove copy temporal previus version
            is_exists_previous_version=$(checkExitsDirectory "$DEPLOYMENT_DIR-old_deploy")
            logger -p local0.debug -it docker-compose-updater "Check if exist previous version"
            if [[ $is_exists_previous_version == 'true' ]]; then
                logger -p local0.debug -it docker-compose-updater "as exists previous version, remove previous version"
                name_folder_old="$DEPLOYMENT_DIR-old_deploy"
                echo "$name_folder_old"
                logger -p local0.debug -it docker-compose-updater "name old folder= $name_folder_old"
                rm -rf "${name_folder_old:?}"
                logger -p local0.debug -it docker-compose-updater "delete folder = $name_folder_old"
            fi
        else
            # Delete the latest deployment with error
            logger -p local0.err -it docker-compose-updater "error deployment lastest version"
            rm -rf "${DEPLOYMENT_DIR:?}/"*
            logger -p local0.debug -it docker-compose-updater "remove ${DEPLOYMENT_DIR} and files"
            # Rename previous version
            mv "$DEPLOYMENT_DIR-old_deploy" "$DEPLOYMENT_DIR"
            logger -p local0.debug -it docker-compose-updater "rename previous version"
            logger -p local0.debug -it docker-compose-updater "old name = $DEPLOYMENT_DIR-old_deploy"
            logger -p local0.debug -it docker-compose-updater "new name = $DEPLOYMENT_DIR"
            # Deploy previous version
            docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml down
            logger -p local0.debug -it docker-compose-updater "deploy previous version whit command (docker compose -f $DEPLOYMENT_DIR/docker-compose.yml down)"
        fi
    else
        logger -p local0.err -it docker-compose-updater "No internet conection"
        docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
        logger -p local0.debug -it docker-compose-updater "deploy previous version whit command (docker compose -f $DEPLOYMENT_DIR/docker-compose.yml down)"
    fi
fi
logger -p local0.debug -it docker-compose-updater "End docker-compose-updater"