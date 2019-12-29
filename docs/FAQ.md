# Frequently Asked Questions

Well, maybe not _frequently_ given the low release number, but things worth knowing.

# Template creation

## Handling apt keys
The DUE install scripts will automatically add any keys for an APT repository. The FRR template has an example of pulling a key and adding a custom repository to the sources.list in its container.

## Soft links to include other files.
See `templates/frr/filesystem/usr/local/bin` for a relative path link to the debian-package's `duebuild` script for building debian packages.

## The template README files supply default build instructions
DUE scans all `template/<name>/README.md` files and looks for a line starting with:  
`Create default frr build environment with: `
...when `due --create help` is run. If you are creating your own templates, I _highly_recommend_ putting this in there.
During development it is very useful to have DUE kick out a complete command to build and image.

## Local vs system installed execution
Running `./due` has it access only files in the local directory. Running `due` will have it use the version installed on the
host system (if it has been built and installed as a package). Depending on the context, local template directories may
be available (./due) or not.
This is useful if you're debugging on a shared user system and don't want to break everybody else.

## Where do I find more containers?
Browse [https://hub.docker.com](https://hub.docker.com/) for images to use with --from

## Cross architecture support
DUE will use QEMU to run containers of alternate architecture types.  The templates/debian-package/README.md has an example of using an armv5 container to use as a build environment on an x86 system.
Cross compilation may be faster, but this is very convenient.


# Run time

## How do I know that I am in a container?  
There are a couple of options.  
First,  If there is a `/.dockerenv` file - you're in a container.  
Second, if the container was created by DUE,  the bash prompt (PS1)
may hint this if the container's `/etc/due-bashrc` is sourced.

If your home directory in the container already has a `~/.bashrc`, and it sets `PS1`, it will
override the container.  
If desired, you can get around this by either:  
1. Sourcing the `/etc/due-bashrc` on log in with `. /etc/due-bashrc`  
OR  
2. Adding the following to the end of your `~/.bashrc`  

`if [ -e /etc/due-bashrc ];then`  
`   	. /etc/due-bashrc`  
`fi`  


## How do I specify a container from the command line and skip menu selection?

Use `due --run --image <name>`  Due uses `<name>` as a `*name*` wildcard match, and if there is only one match,
 runs that image. Otherwise you'll get the menu.

## Can I log in to a running container?
Yes, use `due --login`, which will show all running DUE created containers, and should log you in as yourself.
This is handy if you're used to working with multiple terminals.

## Can I use DUE with containers it did not create?
Yes, although functionality will be limited.

`due --run --any` will show all Docker images. Note that for images not created by DUE, you may need to
add the --username and --userid options to have an account to log in as. The root account usually works, so:

`due --run --any --username root --userid 0` will probably get you a sane environment.

## Well, can I log in to containers that DUE did not create?
Yes - `due --login --any` will show all running containers on the system, although you'll probably want
to supply `--username root --userid 0` if the container wasn't created by DUE.

## On using `--privileged`. Do. Not. Recommend.
The `--privileged` option gives a Docker container access to host device entries that would normally
not be accessible. This can be useful for things like loopback mounting a filesystem to write to it.
However this also allows the container to modify the host system, and presents a **security/stability** risk.
By default DUE does not support this option. It absolutely has its place, but the risk is that because,
generally speaking, anything done to a container is reset on exit, new users will have a false sense of
security and may make changes to the host system itself.
The best practice is to try and avoid running with `--privileged` whenever possible.

# Debugging
See `docs/Troubleshooting.md`

# Design

## Why Bash?
A couple of reasons:

1.  I wanted the user to be able to easily modify existing code, and Bash seemed to be the
lowest common denominator for programming experience. If one can use the command line, they've
got half of Bash programming figured out already.  

2.  Bash is pretty much installed everywhere, and is a bit more flexible than sh/dash.  

3.  Bash scripts aren't architecture dependent, so DUE should run on any Debian system that supports Docker.  

## Why just Debian, and not another Linux?
If you read the History section, you'll know I've mainly been working with Debian and some Ubuntu, so development
here overlapped with tackling problems that needed immediate solutions, so that's where all the testing and development
has been on Debian. DUE could easily be smart enough to work with other Linux distributions, given some debug time.
I'd see the main obstacle being to make the installer scripts aware of alternatives to APT for package management.
Plus being Debian compatible covers running Ubuntu and a few other distributions as well, so it seems like really
good coverage for the amount of effort.

## Why not just a docker file?
Yeah, I asked myself this quite a bit, wondering if I was reinventing the wheel here, and came to a few conclusions:

### Easier development
On the development side, I see a few advantages to generating the Dockerfile than directly editing it:  
1. A **default directory structure** makes adding files to the image very obvious. Ex: files under `filesystem/usr/bin` go in `/usr/bin`.  
2. **Pre** and **post install scripts** make it obvious where those scripts will execute in the install process.  
3. **Softlink awareness** allows copying files between templates for assembly without requiring multiple copies of the file. Ex: the FRR template steals the `duebuild` script from the `debian-package` template using a softlink.  
4. **Template processing** allows for minor detail change details between builds. Ex: setting the container identity with --from allows for a Debian 10 or Ubuntu 16.04 container to be built with exactly the same configuration.  
5. **Debugging inside the container** is easier as DUE puts all the files used in container creation in the container, and they can be run individually inside to narrow down issues.  
6. And it allows for **embedding default information** into the container that can be parsed at runtime (see **Easier Runtime**, below).  
...and in the end, there is a Dockerfile created that does all this, but the user doesn't have to do as much work.  

### Easier Runtime
From a user perspective, Docker is very flexible, but this comes with the cost of complexity, and I'd found insofar as build environments went, I was doing the same few operations over and over, with minor variants. Things like remembering a container name, or setting myself up with the same account on my host system were just a hassle.
By having DUE use a number of defaults and some simplified arguments at run time reduces the typing (and, in my case, resulting errors) to make things more friendly.  

Insofar as I can tell, any of the following can't easily be done with a Dockerfile.

So things like:  
  * Auto creation of a matching **user account** in the container.  
  * Auto mounting the user's **home/work directory** so their configuration is available, and work can be saved when the container exits.  
  * A **selection menu** for available containers, rather than having to remember the container name.  
  * Labels embedded in the container that provide **defaults for running** the container. Example: Debian package builds put the build products one level up from the current directory. DUE debian-package containers know to mount the host directory one level up in the container so that build products are seamlessly there when the container exits. Seems simple, but it's super irritating if it is not there.  
