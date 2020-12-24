# Dedicated User Environment (DUE)

DUE is a wrapper for Docker to create easy to use build environments.  

## The TL:DR

Start with a Docker image for your desired Debian based operating system  
**+**  
DUE configuration utilities  
**+**  
configuration for your build target  

**=**  DUE image.  

The due launcher application will run this image with defaults specified by the image itself, so that
building, regardless of the target's architecture or operating system, can be as easy as:  

### `due --build`  


See **./docs/GettingStarted.md** to get started creating and running an example image.  
Or run `./due --help`
to jump right in with the comprehensive command line help and examples.


## The elevator pitch
Need to build for Debian 8 armel, but only have an x86 host with Ubuntu 18.04?  
DUE supports building for **different architectures** and **OS versions**.

Tired of users missing a step in configuring the build dependencies for your software?
Supply a "template" to configure a Docker image and now everybody is using DUE
to **build in identical environments**.

Painfully aware you're building in a container because the configuration
you'd get from your home directory isn't present, and you have to copy files around?
DUE lets you **be yourself in a container**.

## Talks and tutorial videos
[Building ONIE](https://www.youtube.com/watch?v=-5onRbZA0QQ)  
[DebConf 20 talk on building everything with DUE](https://meetings-archive.debian.net/pub/debian-meetings/2020/DebConf20/7-due-a-container-manager-for-building-things-that-arent-debianized-and-things-that-are.webm)  
[Package build demo from DebConf 20](https://youtu.be/8h60O8O0RcY )  

## The L:DR
If you're building software, odds are it requires some level of build environment configuration.
Docker containers can be used to replicate that environment, and DUE can be used to make
that experience not suck. A listing of the problems DUE solves requires a bit of context
to explain how the design requirements were determined, so bear with me while I get in to
a bit of:

# History
**Dedicated User Environment** came out of build environment design work I'd done at Cumulus Networks,
and they were gracious enough to allow me to open source it. Cumulus Linux is a Debian based operating
system for white box network switches, and the Debian build infrastructure was great...until we had to
start building things that weren't already part of Debian, and for licensing reasons, could never be.  
The scope of things to build expanded for me when I also took on the position of  Open Network Install Environment
project lead, working with the Open Compute Foundation, and needed to support pull requests, debug 
and image build testing for what is essentially a tiny operating system.  
I was already using Docker for Debian package builds, and a Dockerfile build environment had already been created for ONIE,
which left me wondering why there wasn't a set "template" that could be used to set up dedicated build environments?
Especially for distributed  open source projects where developers can't be sharing the same hardware,
but could use a common development environment for debug.

Incidentally, this history explains why most of the starter image templates have a networking focus...  

# Design

## Design requirements
(Or, what am I trying to solve here?)

1. **Easy build environment setup** by using a "template" for build environments.
Whoever wrote the software I'm trying to build has already solved the
problem of setting up things to build - why have developers solve the problem again?

2. Easy setup leads to **identical build environments** for debugging build issues.
There is no more comparing versions of packages installed between systems because everybody is using the same environment.

3.  **Preserve build environments.** I hate it when a software update breaks my ability to build something.
Changes are almost always well intentioned, but mid-development is frequently not the time to tackle compatibility issues.
For example, older platform builds on ONIE haven't been updated for modern kernels, and may never be,
but providing an age-appropriate build container will allow for rebuilding them with bug fixes, should anyone be inclined.

4.  Create a **build environment that feels 'natural'**. I don't want to have to be 'build user' or 'root' in a
container that has none of my configuration, where I have to copy files around to get them out of the container.
I want to feel like I'm still on my host system - with a contextual indicator being the only thing to remind me
that I'm not.

5.  I want **builds to "just work"** without a 'but'. If I'm currently building for Debian 10 and need to build for
Ubuntu 16, it's _almost_ the same thing, 'but' package versions are different.
Well, give me an environment with the different versions and I'll build there.

6.  It has to be **easy to use**, because I'll be encouraging people with priorities other than designing build
environments to use it, and, apart from being friendly, the less the end user has to do, the less support I'll have to do.

7.  It has to be **easy to modify**, since developer requirements will vary. By writing it with Bash scripts the code
resembles the commands the developers would want to run anyway.

8.  It has to work on **shared user systems**. Many users should be able to run containers off the same image without colliding.

9.  It should **work with build automation**. I want developers using the same environment my automated build code
will use so that bugs caused by environmental discrepancies can be avoided.
This is a variant of #2, but I think it's significant enough to warrant its own mention.

10.  The framework for this should be **commonly available** so that developers can distribute their own templates and know end users
can easily obtain the framework to turn those templates into build environments.

# Getting started
See  **docs/GettingStarted.md** for instructions to build and run containers with DUE.

# Further reading
See **docs/Troubleshooting.md** and **docs/FAQ.md**

# Build environment support.

Currently DUE supports the following templates which demonstrate different image build configurations.
See their README.md files under the templates/ directory, or run `./due --create --help-examples` for a quick summary.

## example

This is a bare minimum install of DUE which can work offline once the originating container
has been downloaded to the host system. It is a jumping off point for creating your own
templates, or a useful test configuration for debugging common image creation issues.

## debian-package

As the name implies, this template contains configuration for building Debian packages.
The user specifies the Debian based release (Debian 9, Ubuntu 18.04, etc ),
and occasionally architecture ( arm32v5/debian:buster ), to create a directory with a Dockerfile and some additional files.
One of those additional files is a default build script, `duebuild`, which will handle resolving build dependencies,
allowing a build to be invoked by just running the container without logging in to it.

## ONIE

The **O**pen **N**etwork **I**nstall **E**nvironment is an example of configuring a build environment for a
particular target.  There are a number of build dependencies that have to be present,
and at the moment, the ONIE code prefers Debian 9 (Stretch) and does not build with
the tools provided by Debian 10 (Buster). 
Being able to create a Debian Stretch container with all the dependencies already
available saves developers from sorting out if they have the right packages/versions,
as well as also providing a standard environment where build issues can be debugged.

## FRR

The **F**ree **R**ange **R**outing project provides commercial grade network routing.
In addition to having all the packages required to build, this template uses
an APT repository key and additional sources.list entry to pull build dependencies
from the FRR package repository. It also uses a relative path link to copy the `duebuild` script
from the `debian-package` template, should you be building FRR for a Debian distribution.

## Additional Base Images
...can be found at [https://hub.docker.com](https://hub.docker.com/)

