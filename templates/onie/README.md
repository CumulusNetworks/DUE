# Open Network Install Environment

Create ONIE build environments using a Debian 8 (Jessie) or Debian 9 (Stretch) image.  
**Note** The Debian 9 version is recommended for new platforms.
Currently Debian 10 (and related releases) aren't supported by ONIE.  

## ONIE build environment creation example:
Create the latest default ONIE build environment with: ./due --create --from debian:10  --description "ONIE Build Debian 10" --name onie-build-debian-10 --prompt ONIE-10 --tag onie --use-template onie
**OR**
Create the latest default ONIE build environment with: ./due --create --from debian:9  --description "ONIE Build Debian 9" --name onie-build-debian-9 --prompt ONIE-9 --tag onie --use-template onie  
**OR**  
Create Debian 8 ONIE build environment with: ./due --create --from debian:8  --description "ONIE Build Debian 8" --name onie-build-debian-8 --prompt ONIE-8 --tag onie-8 --use-template onie
### Explanation of the first example:
  * Use a Debian 9 image
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
...Is installed only in Debian 9 (Stretch) based images to update ONIE documentation, as it is the configuration
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

## Debugging
Or, a descriptive collection of ways things have failed. Expect this list to grow.  

**Error:**     configuration failure. In particular, "Can't find bash version > 3.1"  
**Solution:**  This happened when I used ; rather than \; using --command to build an ONIE target.  
**Explanation:** The container runs, taking the text prior to the ;, then bash executes the rest of it locally - outside the container - and this change of state has long since scrolled off the screen by the time the build dies.  


#  Additional notes:
None.


