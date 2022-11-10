# docker-compose-updater
Bash application that allows updating applications based on docker compose.
The application checks if there is a new release in a given public repository, if there is a new latest version, the application displays the new version and if there is an error in the download, the previous version is restored.
For the application to work correctly you must run the first time without errors so that it can save the previous version if a new version is created.

## Prerequisitos
You need to have the following packages installed on Linux:

* Install docker and docker compose ()
* nohup
* jq
* curl
* wget
* unzip
* sh files must have at least the following permissions:
```
    chmod +x file.sh
```

## How to use
You can use the application in 2 ways:
1. Sequentially to update several but until you update an application, it does not continue with the next one.
For this you must use the 2 sh that are inside the repository (apps-updater.sh.example that must configure it and remove the .example extension, docker-compose-updater.sh).
2. Sequentially to update several but launching each one in the background.
For this you must use the 2 sh that are inside the repository (apps-updater.sh.example that must configure it and remove the .example extension, docker-compose-updater.sh).
3. If you only need to update a single application you should only use the docker-compose-updater.sh file

For all options please read the documentation inside each sh file.
