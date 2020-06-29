# Troubleshooting
...for when things don't go as expected

## Symptom: Docker isn't installed

### Installing Docker without a DUE .deb
If you've downloaded DUE as source, run:  
`sudo apt update ; sudo apt install docker.io git rsync binfmt-support qemu qemu-user-static`  

The last three packages there are optional, but necessary if you want to run alternate architectures.

### Installing Docker through the DUE .deb
The lack of Docker will be obvious on the initial install of the DUE .deb, as you'll see the error:  
 `due depends on docker.io | docker-ce; however:  
 Package docker.io is not installed.
 Package docker.ce is not installed`  

To resolve this, try:
`sudo apt update`  
`sudo apt install --fix-broken`
If that fails (and might, depending on how old the version of your operating system is), try
`sudo apt install docker.io`
...and if that fails, try downloading and installing docker.ce from [https://hub.docker.com](https://hub.docker.com/)

## Symptom: Docker containers don't run (or only run as root).
You'll see `Got permission denied while trying to connect to the Docker daemon socket`
You are probably not a member of the Docker group, so you'll need to:

### Add yourself to the Docker group:  
`sudo usermod -a -G docker <yourusername>`  

You may have to *log out* and back in again for the group change to take effect.
Running `groups` should show `docker` along with your other groups.


## Symptom: Strange failures and permission errors in the container.
Check that the host directory the container is using is a **LOCAL** file system.
I've seen strange permission related errors when Docker is mounting a file system
that is network mounted. If your home directory is **NFS** mounted on your
build system, consider creating a work directory on the host system and using
either `/etc/due/due.conf` or `~/.config/due/due.conf` ( generate this with `./due --manage --copy-config` )
to specify this local work directory as your "home" directory.
You'll probably want to copy config files, etc to the new "home" directory.

## Symptom: Can't mount filesystems/missing dev entries in container.
Certain operations (like loopback mounting files) are restricted within the
container because they would require root level access to the host filesystem.
While Docker containers can run with the --privileged option which would
allow this access, it also provides a false sense of security that actions
taken within the container won't trash the host system.
Bottom line: this _can_ be done, but it carries risks.


## Symptom: Running emulated containers fails.
If QEMU is properly and fully installed, DUE should be able to run containers
of other architectures seamlessly
If you're reading this, then you've found a seam and should file a bug at:
[https://github.com/CumulusNetworks/DUE/issues](https://github.com/CumulusNetworks/DUE/issues)


### Fails with: `standard\_init\_linux.go:211: exec user process caused "exec format error"`
So far this has been the only time I've seen this die, and I tracked it down to my system's
`binfmt-support` not being configured to handle ARM binaries. Ideally, qemu should register
the architectures it can run with binfmt-support, so that when non-native code is encountered,
it can be passed off to qemu.

####Other things to check:
#####Are there qemu-* entries under `/proc/sys/fs/binfmt_misc/`
If  `ls -l /proc/sys/fs/binfmt_misc` doesn't show them, then a few required packages may not be installed. Try:

`sudo apt update ; sudo apt install qemu qemu-user-static binfmt-support`

This should create the entries. If this fails, try reconfiguring 
qemu-user-static, with:  
`sudo dpkg-reconfigure qemu-user-static`  
which should have configured binfmt-support to have the entries. I had to do this on one system, 
for reasons that aren't completely clear to me.

#####Is the binfmt service running? 
List bimfmt files
`systemctl list-unit-files | grep binfmt`  
Restart binfmt-support  
`sudo systemctl restart binfmt-support.service`  

# Debugging a failed image creation

If image creation does not complete, a partial image will have been created with the
name <none>. Running `due --manage --list-images` will list all containers on the 
system with the most recently created ones listed first.  

To get inside the failed container and debug it, run:  

`due --run --any --username root --userid 0`  
`cd /due_configuration`

Here you'll find all the configuration scripts being run to create the container,
so you can run them as needed to track down the failure.

Your home directory will be mounted under `/home/root`, so any file changes you make
can be persisted by copying them there.

## Cleaning up failed images
Run `due --manage --delete-matched none`  
This gets the IDs of all images that have 'none' in their name and generates 
a script named `delete_these_docker_images.sh` that can be run to delete all those images.

--delete-matched filters images with  with `*term-supplied*` so you should 
check that the images listed in the script are, indeed,
the ones you want to get rid of.
