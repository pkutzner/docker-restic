docker-restic
==========

This is a fork of [Johan Smits's](https://hub.docker.com/r/jsmitsnl/docker-restic/) docker-restic image.  It builds upon it by adding the ability to use [rclone](https://rclone.org/) to more easily (and efficiently) use cloud storage for your backend, as outlined in this [blog post](https://restic.net/blog/2018-04-01/rclone-backend) on Restic's site.

Includes:
* [restic](https://restic.net)
* [rclone](htps://rclone.org)
* A slightly modified version of [restic-runner](https://github.com/alphapapa/restic-runner)
* cron / supervisord (for scheduling, when run in --detach mode)

This docker configuration allows for only one backup 'set' (or source) per container.  If you wish to back up more than one 'set', just run another container with some slight adjustments.

----------------------------------------------

Usage
---------
Get latest image
=============
    docker pull pkutzner/docker-restic:latest

Create a configuration directory
========================
Create a local directory to store the necessary configuration files for both restic-runner and rclone.  This directory will be one of two to be mapped in when running the image (the other being the data source to be backed up).  This single directory can contain multiple configurations that can be referenced either using environment variables or command-line switches within the container.  This path will be referenced as `CFGDIR` throughout the remainder of this document.

`mkdir -p SOMEWHERE/restic-runner/{repos,sets}`

`SOMEWHERE` is a path of your choosing.

You can optionally pre-populate a configuration file for rclone as well.  If you do so, you'll need to create the folder structure for it and place it yourself.  If you choose to perform the steps below to configure rclone, the appropriate folder and config file will be created automatically.

`mkdir -p SOMEWHERE/rclone`

Configure rclone
=============
    docker run --rm -it -v CFGDIR:/root/.config \
        pkutzner/docker-restic rclone config

Follow the prompts to set up your remote repository/repositories.  There is an option to encrypt this config if you wish.  If you do so, you'll need to supply the `RCLONE_CONFIG_PASS` environment variable every time you run this image.

See the [rclone documentation](https://rclone.org/docs/) for further information on configuring rclone.  It's straightforward, but the documentation also notes other things not covered by this document.

Verify your configuration by running

    docker run --rm -v CFGDIR:/root/.config \
        pkutzner/docker-restic rclone listremotes

Configure restic-runner
==================
Create a repository configuration file as `CFGDIR/restic-runner/repos/REPONAME` using the following template:

    export RESTIC_REPOSITORY="rclone:RCLONE_BACKEND:PATH"
    export RESTIC_PASSWORD="PASSPHRASE"

    keep_policy=(
        --keep-last=${RESTIC_CLEANUP_KEEP_LAST}
        --keep-daily=${RESTIC_CLEANUP_KEEP_DAILY}
        --keep-weekly=${RESTIC_CLEANUP_KEEP_WEEKLY}
        --keep-monthly=${RESTIC_CLEANUP_KEEP_MONTHLY}
        --keep-yearly=${RESTIC_CLEANUP_KEEP_YEARLY}
    )

Replace `RCLONE_BACKEND` with the backend you configured earlier, and `PATH` with the appropriate path information for the backend you configured.

Create a 'set' configuration file as `CFGDIR/restic-runner/sets/SETNAME` using the following template:

    tag='SETNAME'
    
    include_paths=(
        /data
    )
    
    exclude_if_present+=(
        .nobackup
        .resticignore
    )

Replace `SET_NAME` with whatever you wish to call this set. This tag can be used to filter output in Restic.

Create a global config file at `CFGDIR/restic-runner/runner`  This file must be present, but can be empty.  If it is empty, the repository and set name must be supplied every time the image is run, either through the command-line or via environment variables.  If you wish to not have to worry about suplying this information every time a container is created, you can populate the file as follows:

    repo='REPONAME'
    set='SETNAME'

Initialize your restic repository
=====================
If you have not already done so, initialize the restic repository you created.  This needs to be done only once.  If you are using an existing repository, skip this step.

    docker run --rm -v ~/docker-restic-configs:/root/.config pkutzner/docker-restic restic-runner --repo REPONAME init

Verify the repository
===============
    docker run --rm -v ~/docker-restic-configs:/root/.config pkutzner/docker-restic restic-runner --repo REPONAME  check

Run a manual backup
=================
    docker run --rm -v CONFDIR:/root/.config -v SRCDIR:/data \
        pkutzner/docker-restic restic-runner --repo REPO backup

Verify the backup by listing the snapshots
======================================
    docker run --rm -v CONFDIR:/root/.config pkutzner/docker-restic restic-runner snapshots

Automate backups
================
Automated backups can be accomplished by running the container without any command specified.  By default, backups will run hourly at the top of the hour, and the cleanup process will run at 00:15 daily.  The past 24 hours will be kept, along with the past 7 days, 5 weeks, 12 months, and 7 years.  If you wish to change any of these timings, just supply the appropriate environment variable when running the container.  You can view the current environment variables by running the following command:

    docker inspect -f '{{range $index, $value := .Config.Env}}{{println $value}} {{end}}' pkutzner/docker-restic
