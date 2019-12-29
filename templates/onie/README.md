# Open Network Install Environment

This contianer is configured to build ONIE images using
a Debian 9 Stretch container.
Currently Debian 10 (and related releases) aren't supported
by ONIE

Additional contents:
 None

## Suggested configuration:
	Use a debian 9 container 
	Name it onie-build
	Tag it as onie-build
	Set the prompt in container to be ONIE so the context is (more) obvious
	Merge in the files from ./templates/debian-package when creating the configuraton direcotry

## Image creation example
<br>
Create default onie build environment with: ./due --create --from debian:9  --description "ONIE Build" --name onie-build --prompt ONIE --tag onie --use-template onie

## Use


### Build as yourself

You can use due --run  and select the container built in the previous step, which will
mount your home directory, and allow you to work in the container, provided ONIE is checked out in your home directory.

### Build without interaction
DUE allows commands to be run in a container, so if you want to just build a target
without having to log in to the container:
<br>
1. cd to the onie/build-config directory
<br>
2. Invoke --run --command, and prepend /sbin and /usr/sbin to the PATH in the container so that programs like /sbin/mkdosfs can be found, as follows:

#### Example: building the kvm virtual machine
due --run --command export PATH="/sbin:/usr/sbin:\$PATH" \;  make -j4 MACHINE=kvm\_x86\_64 all
<br>
**NOTE** the **\;** used to separate the two commands to be run in the container. Without the **'\'**,
the invoking shell will interpret everything after the **';'** as a command to be run _after_ invoking DUE.
This can create confusion and complicate debugging as it will not be obvious the second command is failing outside of the container.

## Debugging

Notes on the ways a build can be messed up. Expect this list to grow.
<br>
**Error:**     configuration failure. In particular, "Can't find bash version > 3.1"
**Solution:**  This happened when I used ; rather than \; using --command to build an ONIE target. 
**Explanation:** The container runs, taking the text prior to the ;, then bash executes the rest of it locally - outside the container - and this change of state has long since scrolled off the screen by the time the build dies.
<br>

### The oniebuild user
The post-install-config.sh script installs all the ONIE build
dependences, as expected, but also creates an oniebuild account
that can be logged in to from due by specifying

--username oniebuild
The account has /sbin and /usr/sbin added to the path, as well as
a git user.name and user.email config to keep git from complaining
if actions are taken as that user.

You may notice a lag when logging in using the oniebuild account as
it changes the oniebuild account in the container to match the user ID
of the invoking user.


Additional notes:


