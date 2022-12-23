# Frequently Asked Questions
Copyright 2022,2023 Nvidia Corporation.  All rights reserved.

Well, maybe not _frequently_ but things worth knowing.

# Template creation

## Handling apt keys
The DUE install scripts will automatically add any keys for an APT repository. The FRR template has an example of pulling a key and adding a custom repository to the sources.list in its container.

## Soft links to include other files.
See `templates/frr/filesystem/usr/local/bin` for a relative path link to the debian-package's `duebuild` script for building debian packages. This can be useful if you are creating templates that have common code.

## File duplication
If you find image templates have a lot in common, consider using DUE's directory inheritance model to place shared files. `./templates/redhat` uses this to share files between Red Hat Enterprise Linux and Fedora images.

## The template README files supply default build instructions
DUE scans all `template/<name>/README.md` files and looks for a line starting with:  
`Create` and containing `with:`
...when `due --create help` is run.  
If you are creating your own templates, I _highly_recommend_ putting this in there.
During development it is very useful to have DUE kick out a complete command to build an image, and it creates a convenient starting 
point for new users.

## Local vs system installed execution
Running `./due` has it access only files in the local directory. Running `due` will have it use the version installed on the
host system (if it has been built and installed as a package). Depending on the context, local template directories may
be available (./due) or not.
This is useful if you're debugging on a shared user system and don't want to break everybody else.  

**TIP:** DUE will print out the configuration and library files it is sourcing at the start of a run.  
**Example** Here DUE was run from a developer directory and is using the system's configuration file.  
`==== Sourcing DUE files from:     [ /home/adoyle/Dev/DUE ]`  
`==== Sourcing configuration from: [ /etc/due/due.conf ]`  


## Where do I find more containers?
Browse [https://hub.docker.com](https://hub.docker.com/) for images to use with --from

## Cross architecture support
If an image is created that does not match the host processor's architecture, DUE will attempt to install a statically linked version of QEMU in the container to perform emulation, and will default to labeling the image with the architecture to make it easier to choose at run time.  If DUE cannot find a copy of QEMU in the image template's `post-install-local` directory it will try to use the version of QEMU installed on the host system.  
The templates/debian-package/README.md has an example of using an armv5 container to use as a build environment on an x86 system.


# Run time

## How do I know that I am in a container?  
There are a couple of options.  
Is there is a `/.dockerenv` file? You're in a container run by Docker.  
Is there a `/run/.containerenv` file? You're in a container run by Podman       .  
Does the bash prompt (PS1) look different? Containers created by DUE will change the prompt to help provide a frame of reference.  

### A note on the prompt...
If your home directory in the container already has a `~/.bashrc`, and it sets `PS1`, it will override the container.  
If desired, you can get around this by either:  
1. Sourcing the `/etc/due-bashrc` on log in with `. /etc/due-bashrc`  
OR  
2. Adding the following to the end of your `~/.bashrc`  

`if [ -e /etc/due-bashrc ];then`  
`   	. /etc/due-bashrc`  
`fi`  


## How do I specify an image from the command line and skip menu selection?

Use `due --run--image <name>:<tag>`  Due uses `<name>:<tag>` as a wildcard match, and if there is only one match, DUE runs that image. Otherwise you'll get a menu of matched images.
 
## How do I know what arguments a container's duebuild script will take?

Run `due --duebuild --help` and you can select a container to run `duebuild --help` in.  

## Can I log in to a running container?
Yes, use `due --login`, which will show all running DUE created containers, and should log you in as yourself.
This is handy if you're used to working with multiple terminals.  
**NOTE** if you log into someone _else's_ running container, you will retain your system identity and get a home directory created for you **in the container** rather than having a host mounted one. So any files you save under your home directory will vanish with the container.


## Can I use DUE with containers it did not create?
Yes, although functionality will be limited.

`due --run --any` will show all Docker images. Note that for images not created by DUE, you may need to add the `--username` and `--userid` options to have an account to log in as. The root account usually works, so:

`due --run --any --username root --userid 0` will probably get you a sane environment.

## Well, can I log in to containers that DUE did not create?
Yes - `due --login --any` will show all running containers on the system, although you'll probably want to supply `--username root --userid 0` if the container wasn't created by DUE.  
Or use `due --login --debug`, which is a shortcut to log you in as root.

# Changing the defaults - DUE's config file(s).
DUE's configuration files are at `/etc/due/due.conf` for the system, and `~/.config/due/due.conf` for individual users.  

These allow the settings of a few variables:  
1. Maximum containers to allow a user to run.  
2. The location of a user's home directory.  
3. If user's config files can override the system wide config in /etc/due/due.conf.  
4. Default run time arguments based on the type of container being run.  

While the first three are relatively self-explanatory, the fourth option gets really interesting.  `libdue` sources the config file (system or user) to override `fxnSetContainerSpecificArgs()` and provide default Docker arguments based on the type of container being run. This allows for things like:  
  * Mounting a host directory by default.  
  * Supplying a hostname/IP address to the container's /etc/hosts file.  
  * Running a container `--privileged` by default (more on that, below).  
  
In prior releases this functionality was in `libdue`, but since per-site/user customization is extremely convenient, and these sorts of customizations will never be universal enough to be upstreamed it has been moved to the configuration files, which are sourced by DUE. To get started, some commented out examples have been provided in the config files, and end users can deploy them either system wide (`/etc/due/due.conf`) or on a per user basis (`~/.config/due/due.conf`)  
   
Again, as it may not be a good idea to give system users too much creative freedom, 
the scope of customization is initially limited to`/etc/due/due.conf` by having `DUE_ALLOW_USER_CONFIG` set to `FALSE` in the config file. DUE will read the `/etc/due/due.conf` file first, and will only source user `due.conf` files if `DUE_ALLOW_USER_CONFIG` is set to `TRUE`.  
Can users work around this? Sure. But the point is that they can't do it by accident.  


## On using `--privileged`. Do. Not. Recommend.
The `--privileged` option gives a Docker container access to host device entries that would normally
not be accessible. This can be useful for things like loopback mounting a file system to write to it,
or having a container that runs other containers.  
**However** this also allows the container to modify the host system, and presents a **security/stability** risk,
as users in the container may be able to affect the host system without realizing they are doing so.
Within DUE it was a deliberate design choice to make things like this inconvenient so that the user has to be  acutely aware of what they are doing.

## Using `--privileged` ...if you have to.
If you are indeed in a situation where this is necessary, `--privileged` can be passed to the command line
invocation of Docker by using `due --run --dockerarg "--privileged"`. The `--dockerarg` option passes the following parameter through. It can be used multiple times for multiple arguments.
If you need to have a container that has Docker installed in it to run other containers, an example invocation would be:
`due --run --dockerarg "--privileged" --mount-dir "/dev:/dev" --mount-dir "/var/run/docker.sock:/var/run/docker.sock"`
Note that this does mount two directories from the host system that can be modified by the container.
**Use with caution.**


# Debugging
See `docs/Troubleshooting.md`

# Design

## Why Bash?
A couple of reasons:

1.  I wanted the user to be able to easily modify existing code, and Bash seemed to be the
lowest common denominator for programming experience. If one can use the command line, they've
got half of Bash programming figured out already.  

2.  Bash is pretty much installed everywhere, and is a bit more flexible than sh/dash.  

3.  Bash scripts aren't architecture dependent, so DUE should run on any Linux system that supports Docker/Podman.  

## Why not another Linux?
If you read the History section, you'll know DUE came out of working with Debian and some Ubuntu, so most of the development here overlapped with tackling problems that needed immediate solutions and has had better testing in those environments.  
Recently I've started working with RPM builds and Podman, so support for these environments has been introduced and is being tested in the hopes that it will eventually be as robust as the Debian support (translation - the RPM stuff should be considered a bit 'beta')    
  

## Why not just use a Docker file?
Yeah, I asked myself this quite a bit, wondering if I was reinventing the wheel here, and came to a few conclusions:

### Easier development
On the development side, I see a few advantages to generating the Dockerfile than directly editing it:  
1. A **default directory structure** makes adding files to the image very obvious. Ex: files under `filesystem/usr/bin` go in `/usr/bin`.  
2. **Pre** and **post install scripts** make it obvious where those scripts will execute in the install process.  
3. **Softlink awareness** allows copying files between templates for assembly without requiring multiple copies of the file. Ex: the FRR template steals the `duebuild` script from the `debian-package` template using a softlink.  
4. **Template processing** allows for minor detail change details between builds. Ex: setting the container identity with --from allows for a Debian 10 or Ubuntu 16.04 container to be built with exactly the same configuration.  
5. **Debugging inside the container** is easier as DUE puts all the files used in container creation in the container, and they can be run individually inside to narrow down issues.  
6. **Current user identity is preserved** by wrapping the Docker invocation (see below)
6. It allows for **embedding default information** into the container that can be parsed at Runtime (see **Easier Runtime**, below).  
...and in the end, there is a Dockerfile created that does all this, but the user doesn't have to do as much work.  

### Easier run time
Docker can't control how it is launched, so it is all on the user to handle the complexity that arises from starting a container. Having a program that wraps the launch, and understands what is being run allows for the user to have a much easier time of it. I found I was doing the same few operations over and over, with minor variants. Things like remembering a container name, or setting myself up with the same account on my host system were just a hassle.
By having DUE use a number of defaults and some simplified arguments at run time it reduces the typing (and, in my case, resulting errors) to make things more friendly.  

Insofar as I can tell, any of the following can't easily be done with a Dockerfile.

So things like:  
  * Auto creation of a matching **user account** in the container.  
  * Auto mounting the user's **home/work directory** so their configuration is available, and work can be saved when the container exits.  
  * Logging in to a running container with one's host system identity.
  * A **selection menu** for available containers, rather than having to remember the container name.  
  * Labels embedded in the container that provide **defaults for running** the container.   
  * Example: Debian package builds put the build products one level up from the current directory. DUE debian-package containers know to mount the host directory one level up in the container so that build products are seamlessly there when the container exits. Seems simple, but it's super irritating if it is not there.  
  
  
  




 
