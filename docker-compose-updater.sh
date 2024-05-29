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

# Wait time to check the internet connection - Only optional for check connection internet
sleep 10

# Syslog variable
app="$(echo "$1" | tr '/' '-')"

# Get latest version
logger -p local0.debug -it docker-compose-updater-app-"$app" "Start docker-compose-updater"
get_latest_release() {
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Start function get latest version"
    GITHUB_REPO="$1"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "GitHub Repository = $1"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Get tag name parameter from repository"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "github url: 'https://api.github.com/repos/$GITHUB_REPO/releases/latest'"
    curl --silent "https://api.github.com/repos/$GITHUB_REPO/releases/latest" |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/'
    logger -p local0.debug -it docker-compose-updater-app-"$app" "End function get latest version"
}

# Download a new realease
download_release_file() {
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Start function download release file"
    GITHUB_REPO="$1"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "GitHub Repository = $1"
    TMP_DIR="$2"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Temporal directory = $2"
    ZIP_FILE="$TMP_DIR/$3.zip"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Zip file = $ZIP_FILE"

    detect_release=""
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Start check release"
    check_release="$(curl -Ls --location --request GET curl -Ls --location --request GET https://api.github.com/repos/"$GITHUB_REPO"/releases/latest | jq -r '.message')"

    if [[ $check_release == 'Not Found' ]]; then
        detect_release="false"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Assing variable detect_release = $detect_release)"
        echo "Error: the project not have releases"
        logger -p local0.err -it docker-compose-updater-app-"$app" "the project not have releases"
    else
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Show git repository to extract and download info"
        curl -Ls --location --request GET https://api.github.com/repos/"$GITHUB_REPO"/releases/latest |
            jq -r ".zipball_url" |
            wget -qi - -O "$ZIP_FILE" &&
            unzip -q -o "$ZIP_FILE" -d "$TMP_DIR" &&
            cp -R "$TMP_DIR"/"$(unzip -Z -1 "$ZIP_FILE" | head -1)"/* "$TMP_DIR" &&
            rm -R "${TMP_DIR:?}/$(unzip -Z -1 "$ZIP_FILE" | head -1)/" &&
            rm "$ZIP_FILE"

        detect_release="true"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Assing variable detect_release = $detect_release)"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Extract zipball_url parameter from github repository"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Download  $ZIP_FILE"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Extract  $ZIP_FILE in $TMP_DIR"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Move files unziped and clean folders"
    fi

    logger -p local0.debug -it docker-compose-updater-app-"$app" "End function download release file"
    echo "$detect_release"
}

# Function check exists directory
checkExitsDirectory() {
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Start function check if exits directory"
    directory="$1"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Directory to check = $directory"
    retval=""
    if [[ -d "$directory" ]]; then
        retval="true"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Assing variable (if exists directory = $retval)"
    else
        retval="false"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Assing variable (if not exists directory = $retval)"
    fi
    echo $retval
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Directory exists?= $retval"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "End function check if exists directory"
}

checkExitsFile() {
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Start function checkexistsfile"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Check exists file argument"
    file="$1"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "File argument = $1"
    retval=""
    if [[ -f "$file" ]]; then
        retval="true"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Assing variable (if exists file = $retval)"
    else
        retval="false"
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Assing variable (if not exists file = $retval)"
    fi
    echo $retval
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Exist file argument= $retval"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "End function checkexistsfile"
}

GITHUB_REPOSITORY="$1"
logger -p local0.debug -it docker-compose-updater-app-"$app"-app:"$1" "GITHUB REPOSITORY = $1"
path="$2"

isexistpath=$(checkExitsDirectory "$path")

if [ "$path" != "" ]; then
  if [ "$isexistpath" == 'true' ]; then
    DEPLOYMENT_DIR="$path/$1"
    logger -p local0.debug -it docker-compose-updater-app-"$app"-app:"$1" "Path path to deployment: $DEPLOYMENT_DIR"
    echo "Path path to deployment: $DEPLOYMENT_DIR"
  else
    echo "Path not exist or is null, run script with default: $DEPLOYMENT_DIR"
    logger -p local0.debug -it docker-compose-updater-app-"$app"-app:"$1" "Path not exist or is null, run script with default: $DEPLOYMENT_DIR"
    DEPLOYMENT_DIR="$1"
  fi
fi

logger -p local0.debug -it docker-compose-updater-app-"$app" "DEPLOYMENT DIRECTORY = $1"
TMP=$(cat "$DEPLOYMENT_DIR"/LATEST_VERSION.txt 2>/dev/null || true)
logger -p local0.debug -it docker-compose-updater-app-"$app" "Create temporal file= $TMP"
CURRENT_VERSION="${TMP:-0.0.0}"
logger -p local0.debug -it docker-compose-updater-app-"$app" "Current version= $CURRENT_VERSION"
LATEST_VERSION=$(get_latest_release "$GITHUB_REPOSITORY")
logger -p local0.debug -it docker-compose-updater-app-"$app" "Latest version= $LATEST_VERSION"

# Check is a new version to deploy
logger -p local0.debug -it docker-compose-updater-app-"$app" "Check is a new version to deploy"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    if [ -e "$DEPLOYMENT_DIR" ]; then
        docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Docker compose Start whit docker-compose.yml file"
    fi
    echo "Docker compose is already running the latest version ($LATEST_VERSION)"
    logger -p local0.debug -it docker-compose-updater-app-"$app" "Docker compose is already running the latest version $LATEST_VERSION"
else
    if [ "$LATEST_VERSION" != "" ]; then
    
        # Check connection to internet
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Check connection to internet"
        wget -q --spider http://google.com
        check_internet=$?
        logger -p local0.debug -it docker-compose-updater-app-"$app" "Check internet = $?"
        if [ $check_internet -eq 0 ]; then
            logger -p local0.debug -it docker-compose-updater-app-"$app" "As the internet is available, update version"
            echo "Docker compose is running an old version (current: $CURRENT_VERSION, latest: $LATEST_VERSION)"
            logger -p local0.debug -it docker-compose-updater-app-"$app" "Docker compose is running an old version (current: $CURRENT_VERSION, latest: $LATEST_VERSION)"
            # Download the latest release's files
            logger -p local0.debug -it docker-compose-updater-app-"$app" "Download the latest relese's files"
            TMP_DIR=$(mktemp -d -t docker-compose-XXXXXXXXXX)
            echo "$TMP_DIR"
            logger -p local0.debug -it docker-compose-updater-app-"$app" "Temporal directory = $TMP_DIR"

            is_exists_release=$(download_release_file "$GITHUB_REPOSITORY" "$TMP_DIR" "$LATEST_VERSION")
            
            if [[ $is_exists_release == 'true' ]]; then
                logger -p local0.debug -it docker-compose-updater-app-"$app" "Use function download_relese_file with variables= $GITHUB_REPOSITORY , $TMP_DIR , $LATEST_VERSION"

                # Copy previous deployment
                logger -p local0.debug -it docker-compose-updater-app-"$app" "Copy previous deployment"
                is_exists_directory_repository=$(checkExitsDirectory "$DEPLOYMENT_DIR")
                logger -p local0.debug -it docker-compose-updater-app-"$app" "Check if exist directory ($DEPLOYMENT_DIR) whit function checkExitsDirectory"
                logger -p local0.debug -it docker-compose-updater-app-"$app" "Directory exist?= $is_exists_directory_repository"
                if [[ $is_exists_directory_repository == 'true' ]]; then
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "As exists directory repository, clone directory with tag old-deploy"
                    # cp -R "$DEPLOYMENT_DIR" "$(echo "$DEPLOYMENT_DIR" | rev | cut -d'/' -f2- | rev)/$(basename "$DEPLOYMENT_DIR")-old_deploy"
                    cp -R "$DEPLOYMENT_DIR" "$DEPLOYMENT_DIR-old_deploy"
                fi

                # Stop the current deployment
                logger -p local0.debug -it docker-compose-updater-app-"$app" "Stop the current deployment"
                if [ -e "$DEPLOYMENT_DIR" ]; then
                    docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml down
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Stop deployment with docker compose"
                else
                    mkdir -p "$DEPLOYMENT_DIR"
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Create directory = $DEPLOYMENT_DIR"
                fi

                # Delete the current deployment
                logger -p local0.debug -it docker-compose-updater-app-"$app" "Delete the current deployment"
                rm -rf "${DEPLOYMENT_DIR:?}/"*
                logger -p local0.debug -it docker-compose-updater-app-"$app" "Move temporal dir to deployment_dir"
                mv "$TMP_DIR"/* "$DEPLOYMENT_DIR"

                # Deploy the application
                existcomposefile=$(checkexistsfile "$DEPLOYMENT_DIR"/docker-compose.yml)
                if [[ $existcomposefile == 'true' ]]; then
                    docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
                    exit_code=0
                else
                    exit_code=1
                fi
                # docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
                logger -p local0.debug -it docker-compose-updater-app-"$app" "Deploy the application using docker compose = (docker compose -f $DEPLOYMENT_DIR/docker-compose.yml up -d)"
                exit_code=$?
                logger -p local0.debug -it docker-compose-updater-app-"$app" "exit code = $?"
                if [ $exit_code -eq 0 ]; then
                    echo "Successfully deploy latest"
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Successfully deploy latest"
                    # Store the latest version and remove temporary files
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Store the latest version and remove temporary files"
                    echo "$LATEST_VERSION" >"$DEPLOYMENT_DIR"/LATEST_VERSION.txt
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Docker compose is now running version ${LATEST_VERSION}"
                    echo "Docker compose is now running version ${LATEST_VERSION}"

                    # Remove copy temporal previus version
                    is_exists_previous_version=$(checkExitsDirectory "$DEPLOYMENT_DIR-old_deploy")
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Check if exist previous version"
                    if [[ $is_exists_previous_version == 'true' ]]; then
                        logger -p local0.debug -it docker-compose-updater-app-"$app" "As exists previous version, remove previous version"
                        name_folder_old="$DEPLOYMENT_DIR-old_deploy"
                        echo "$name_folder_old"
                        logger -p local0.debug -it docker-compose-updater-app-"$app" "Name old folder= $name_folder_old"
                        rm -rf "${name_folder_old:?}"
                        logger -p local0.debug -it docker-compose-updater-app-"$app" "Delete folder = $name_folder_old"
                    fi
                else
                    # Delete the latest deployment with error
                    logger -p local0.err -it docker-compose-updater-app-"$app" "Error deployment lastest version"
                    rm -r "$DEPLOYMENT_DIR"
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Remove ${DEPLOYMENT_DIR} and files"
                    # Rename previous version
                    mv "$DEPLOYMENT_DIR-old_deploy" "$DEPLOYMENT_DIR"
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Rename previous version"
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Old name = $DEPLOYMENT_DIR-old_deploy"
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "New name = $DEPLOYMENT_DIR"
                    # Deploy previous version
                    docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
                    logger -p local0.debug -it docker-compose-updater-app-"$app" "Deploy previous version whit command (docker compose -f $DEPLOYMENT_DIR/docker-compose.yml down)"
                fi
            else
                echo "Error: not exists releases"
                logger -p local0.debug -it docker-compose-updater-app-"$app" "Not exists releases"
            fi

        else

            logger -p local0.err -it docker-compose-updater-app-"$app" "No internet conection"
            docker compose -f "$DEPLOYMENT_DIR"/docker-compose.yml up -d
            logger -p local0.debug -it docker-compose-updater-app-"$app" "Deploy previous version whit command (docker compose -f $DEPLOYMENT_DIR/docker-compose.yml down)"
        fi
    fi
fi
logger -p local0.debug -it docker-compose-updater-app-"$app" "End docker-compose-updater"
