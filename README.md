# docker-compose-updater
Bash application that allows the update of applications based on docker compose.
The application checks if there is a new release in a given public repository, if there is a new latest version, the application displays the new version and if there is an error in the download, the previous version is restored.
For the application to work correctly you must run the aplication first without error, so that it can save the previous version if a new one is created.

## Prerequisitos
You need to have the following packages installed on Linux:

* Install docker v20.10.21 and docker compose v2.12.2
* nohup v8.30
* jq v1.6
* curl v7.68.0
* wget v1.20.3
* unzip v3.0-11
* sh files must have at least the following permissions:
```
    chmod +x file.sh
```
* It must be taken into account that the parent folder where this application is going to be executed, it is recommended to create a user other than root with permissions `rwxr-xr-x` or `755` and that the content of the same folder is also inherited


## How to use
You can use the application in 3 ways:
1. Sequentially to update multiple apps, but each app must finish before the next one starts.
For this you must use the two (2) ``sh`` that are inside the repository (``apps-updater.sh.example`` that you must configure and remove the .example extension, ``docker-compose-updater.sh``).
2. Sequentially to update multiple apps, but launching each one in the background.
For this you must use the two (2) ``sh`` that are inside the repository (``apps-updater.sh.example`` that you must configure and remove the .example extension, ``docker-compose-updater.sh``).
3. If you only need to update a single application you should only use the ``docker-compose-updater.sh`` file

For more information and expansion of options, please read the documentation inside each ``sh`` file.
