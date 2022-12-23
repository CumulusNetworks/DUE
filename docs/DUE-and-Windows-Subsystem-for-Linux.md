# DUE and Windows Subsystem For Linux
Copyright 2022,2023 Nvidia Corporation.  All rights reserved.

DUE has been confirmed to run on WSL 2 using Ubuntu 20.04 and Podman.
Other configurations may work, but have not been tested.

Using Podman in WSL requires a bit more configuration, and users may
encounter a few more issues, so this topic deserves its own document.

## Why Podman?
I'd had issues getting the Docker daemon going in WSL, but as Podman
is daemonless, it will run fine.  Just make sure to install Podman
**BEFORE** trying DUE's `make install` as the Makefile will see the
system as Ubuntu, and will want to install `docker.io`.


## Powershell
Make sure your Ubuntu instance is using WSL version 2:

Type: `wsl -l -v`

If it is not, set the version of the instance with --set-version.  
**Example:**  wsl `--set-version Ubuntu-20.04 2`

## Pulling containers
As Podman and Docker have different approaches to handling container
images, the `--from` creation commands may need to explicitly reference docker.io.  
**Example:** Pull a debian 10 container from docker.io  

`./due --create --from docker.io/library/debian:10 --description "Debian 10 example" --name example-debian-10 --prompt Ex --tag example-debian-10 --use-template example`

## Troubleshooting
Note that this is not a complete list of things that may happen, but rather the
issues I've tripped over so far...

**Symptom:**  Warn [0000] "/" is not a shared mount...  
**Seen:**  When creating a new DUE container.  
**Solution:** `sudo mount --make-rshared / ; sudo usermod --add-subuids 200000-201000 --add-subgids 200000-201000 $(whoami)`

**Symptom:** command required for rootless mode with multiple IDs: exec: "newuidmap":
 executable file not found in $PATH  
**Seen:**  When running a container for the first time.  
**Solution:** `sudo apt-get install uidmap`

**Symptom:** ERROR[0000] could not find slirp4netns, the network namespace won't be configured: exec: "slirp4netns": executable file not found in $PATH  
**Seen:** When running a container for the first time.  
**Solution:** `sudo apt-get install slirp4netns`

**Symptom:** Error: Unsupported pull policy <container id>  
**Seen:** When trying to run a container using Podman.  
**Solution:** Use full image name and tag in invocation. This alleges to be fixed in newer versions of Podman (though not new enough that I could find a copy), and it's not clear to me why the pull policy, which is used for container creation is showing up at container runtime.
