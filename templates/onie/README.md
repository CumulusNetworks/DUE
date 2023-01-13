# Open Network Install Environment
Copyright 2022,2023 Nvidia Corporation.  All rights reserved.

Create ONIE build environments using a Debian 8 (Jessie), Debian 9 (Stretch) or Debian 10 (Buster) image.  
**Note** Most targets build using Debian 9. Debian 10 support is in beta testing.

## ONIE build environment creation example:
Create default Debian 11 build environment with: ./due --create --platform linux/amd64    --name onie-build-debian-11    --prompt ONIE-11      --tag onie                    --use-template onie              --from debian:11                             --description "ONIE Build Debian 11"  
**OR**  
Create default Debian 10 build environment with: ./due --create --platform linux/amd64    --name onie-build-debian-10    --prompt ONIE-10      --tag onie                    --use-template onie              --from debian:10                             --description "ONIE Build Debian 10"  
**OR**  
Create default Debian 9 build environment with: ./due --create --platform linux/amd64    --name onie-build-debian-9     --prompt ONIE-9       --tag onie                    --use-template onie              --from debian:9                              --description "ONIE Build Debian 9"  
**OR**   
Create default Debian 8 build environment with: ./due --create --platform linux/amd64    --name onie-build-debian-8     --prompt ONIE-8       --tag onie-8                  --use-template onie              --from debian:8                              --description "ONIE Build Debian 8"  

### Explanation of the first example:
  * Use a Debian 10 image
  * Name it onie-build
  * Tag it as onie-build
  * Set the user's PS1 prompt in the image to be ONIE so the context is (more) obvious
  * Merge in the files from ./templates/onie when creating the configuration directory

## Additional configuration
This lists changes that are unique to this container.

### The oniebuild user
The `post-install-config.sh.template` script installs all the ONIE build
dependencies, as expected, but also creates an oniebuild account
that can be logged in to from due by specifying

`--username oniebuild`
The account has /sbin and /usr/sbin added to the path, as well as
a git user.name and user.email config to keep git from complaining
if actions are taken as that user.

You may notice a lag when logging in using the oniebuild account as
it changes the oniebuild account in the container to match the user ID
of the invoking user.

### Python-sphinx
...Is installed only in Debian 9 (Stretch) and 10 (Buster) based images to update ONIE documentation, as it is the configuration
used for ONIE quarterly releases. Users can add/remove this by editing the `post-install-config.sh.template`
prior to image creation.

# Use

## Build as yourself

You can use `due --run`  and select the image built in the previous step, which will:

1.  Mount your "home" directory ( this doesn't have to be your host's ~/ - see `docs/GettingStarted.md` )
2.  Create an account for you in the container, with your username and user ID.
3.  Source a .bashrc, and allow access to any other . files.
4.  ...and now you can navigate to the onie directory, to build from the command line.  


## Build without interaction

There are a number of ways to use the container to build ONIE without logging in
to the container.  
**Tip** Use the `--run-image image-name:image-tag` argument to skip the image selection menu if you already know which image and tag you want to run.


See `DUE/docs/Building.md` for additional information.

Start by: cd -ing to the onie/build-config directory.
DUE will auto-mount the current directory if it is running a command rather than a login.

Then try one of the following:

### Using `--command`
**Purpose:** execute everything after --command in a Bash shell.  
**Description:** Here the container executes everything after `--command` in a Bash shell.  
**Example:** due --run --command export PATH="/sbin:/usr/sbin:\$PATH" \; make -j4 MACHINE=kvm\_x86\_64 all  
**Example:** due --run --command export PATH="/sbin:/usr/sbin:\$PATH" \; make MACHINEROOT=../machine/accton MACHINE=accton_as7112_54x all demo recovery-iso  

**NOTES:**  
1.  The **\;** used to separate the two commands to be run in the container. Without the **'\'**,
the invoking shell will interpret everything after the **';'** as a command to be run _after_ invoking DUE.  
This can create confusion and complicate debugging as it will not be obvious the second command is failing outside of the container.  
2.  The addition of /sbin and /usr/sbin to the path is only needed if you are making the recovery-iso target.


### Using `--build`
**Purpose:** Use container's `duebuild` script to perform additional configuration.  
**Description:** Here, `--build` is a shortcut to invoke the `/usr/local/bin/duebuild` script in the container, and provide
a bit of abstraction so as to not bother the user with the details of the build.  
**Tip:** get help for the container's `duebuild` script by running: `due --run --build help`

#### Using `--build --default`
**Purpose:** This will build a target that should always work to sanity check the build environment.  
**Description:** This will vary based on the role of the image, but in the case of ONIE it will build the kvm-x86 virtual machine since that target does not require switch hardware to run, and thus should be usable everywhere.

#### Using `--build --cbuild`
**Purpose:** The `--cbuild` option allows for default configuration of the environment before build, but that really
doesn't apply to ONIE, so here it just passes the make string straight through, the same way `--command` would.  
**Example:** due --run --build --cbuild make -j4 MACHINE=kvm_x86_64 all demo recovery-iso  
**Example:** due --run --build --cbuild make -j4 MACHINEROOT=../machine/accton MACHINE=accton_as7112_54x all demo recovery-iso  

#### Using additional duebuild arguments for ONIE
Here the duebuild script can provide some convenience in the build by specifying the build
details as arguments that then get passed to a makefile. The benefit here is that the MACHINEROOT gets
determined by searching for the MACHINE.
It's just another way of arriving at the final makefile invocation, however.  

**Example:** due --run --build --jobs 4 --machine kvm_x86_64 --build-targets all demo recovery-iso  
**Example:** due --run --build --jobs 4 --machine accton_as7112_54x --build-targets all demo recovery-iso  

## Mounting host directories
The ONIE container will try to mount the following directories from the host system. Failure to do so may result in an error (if operations absolutely cannot proceed) or a warning just to let the user know what is happening.

#### /home/*username*
**If missing:** Error.  
**Used for:** Access to the user's default environment and configuration. The invoking user's home directory is always mounted.  

#### Current Working Directory
**If missing** Error.  
**Used for:** When the container is created to just run a command, rather than support an interactive login, the current working directory will always be mounted.
 
#### /var/cache/onie  
**If missing:** Warning.  
**Used for:** Download cache.  
Rather than having to always download source packages from their original sites, or the [OpenCompute Mirror](http://mirror.opencompute.org/onie),
ONIE can search for source packages in `/var/cache/onie/downloads`, provided `make` is invoked with `ONIE_USE_SYSTEM_DOWNLOAD_CACHE=TRUE` set.  If this directory exists on the host system, all running ONIE containers will have access to it, saving time and bandwidth. While populating the directory is left as an exercise for the system administrator, running  
`wget –recursive –cut-dirs=2 –no-host-directories –no-parent –reject “index.html” http://mirror.opencompute.org/onie/`  
...might be a good starting point.


#### /dev
**If missing:** Warning.  
**Used for:** Loopback mounting filesystems.  
Mounting the host's `/dev` directory is only suggested for certian workflows that require loop back mounting a filesystem. As the host system's `/dev` directory can be modified by actions in the container, the container must be run with Docker's `--privileged` option set to mount this (see below).  
Note that there are usually alternative workflows where loopback mount operations can take place outside of the container, if running privileged is undesirable.

### Running --privileged containers  
Certain ONIE workflows, such as building the KVM target for secure boot, can take advantage of access to the host system's /dev directory to loopback mount filesystems and reduce the amount of required user interaction in a build.  
**Example:** due --run --dockerarg --privileged  
**Example:** due --run-image due-onie-build-debian-10 --dockerarg --privileged  



## Debugging
Or, a descriptive collection of ways things have failed. Expect this list to grow.  

**Error:**     configuration failure. In particular, "Can't find bash version > 3.1"  
**Solution:**  This happened when I used ; rather than \; using --command to build an ONIE target.  
**Explanation:** The container runs, taking the text prior to the ;, then bash executes the rest of it locally - outside the container - and this change of state has long since scrolled off the screen by the time the build dies.  


#  Additional notes:
None.


