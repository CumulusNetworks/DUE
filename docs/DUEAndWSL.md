# DUE and Windows Subsystem For Linux

DUE has been confirmed to run on WSL 2 using Ubuntu 20.04 and Podman.
Other configurations may work, but have not been tested.

Using Podman in WSL requires a bit more configuration, and users may
encounter a few more issues, so this topic deserves its own document.

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
