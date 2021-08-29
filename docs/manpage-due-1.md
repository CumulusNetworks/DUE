% DUE(1) Version 2.4.0 | Dedicated User Environment

# NAME

**due** - Dedicated User Environment. A build environment for your build environments.

# SYNOPSIS

| **due** \[**-r|--run** _args_] \[_dedication_]
| **due** \[   **--create** _args_ ] \[_dedication_]
| **due** \[   **--delete** _term_ ] \[_dedication_]
| **due** \[**-m**|**--manage** _args_] \[_dedication_]
| **due** \[**-v**|**--version**]
| **due** \[**-h**|**--help**]

# DESCRIPTION

DUE is a set of wrapper scripts for both creating Docker container based
build environments, and running them with intelligent defaults so that
the user can feel like they are still on the host system.

Key features include:

 1 - Creating an account in the container for the user at run time and mounting
     the user's home/work directory so configuration files are available.

 2 - List based browsing of images to run and active containers to log in to.

 3 - Use of container 'templates' to pre configure and build containers for a
     particular target or Debian based operating system,
     eliminating errors caused by missing dependencies, or misconfiguration.

 4 - Commands can be run using the container without having to log into it, allowing
     for use in automated build environments.


Functional Options
-------
Each of these options has context specific help and sub commands

-r, --run

:   Start new containers.

--build, --duebuild

:   Execute container's /usr/local/bin/duebuild script in current directory.
    See the --run section for more.

--create

:   Make and configure new Docker images.

--delete <term> 

:   Delete existing Docker images that match the term.

-m, --manage

:   Manipulate and query existing images.

-h, --help

:   Usage information.

-v, --version

:   Print DUE's version number.

--run options
-------
These options are available after the --run argument, and relate to
starting and logging in to containers.

Starting an image
-------

-i, --run-image [filter]
:	Allows the user to reduce the number of images shown
to run by restricting them to entries that contain [filter]. If only one image
matches the filter, it will be invoked without asking the user to choose it.

-a, --all
:	Show all containers on the system. DUE can be used to log in to
containers that it did not create, but the user may have to supply a default
--username and --userid (usually --username root and --userid 0. See below )

--ignore-type
:		 When accessing the container, do not attempt to create a user
account for the user logging in, and assume the container was not created by
DUE. This can be useful with image creation debug.

-c, --command [cmd]
:	Run [cmd] in the container using the --login-shell.
 This must be the last command parsed, as [cmd] is handed off to be run in
 the container. The primary use of this would be using the container to
 build without having to interactively log in to it.
 Note: when issuing multiple commands, remember to "" your arguments, and
 backslash (\) any semicolons (;) used to split up the commands. Otherwise the
 shell where the commands are invoked will take anything after the first ;, and
 treat it as a command to be run locally.
 This can obfuscate things if the command can work inside or out of the container.  
 Example: look at /proc and the password file in a container:
          ./due --run --command "ls -lrt /proc"  \; "cat /etc/passwd"  

--build | --duebuild
:	If there is a /usr/local/bin/duebuild script in the container, this option
    will run it with a default configuration, or take additional passed
	arguments if present. Those arguments will vary depending on the nature of
	the target being built by the container's duebuild script.
	For more information, check the template/README.md for the image type, or
	use: due --duebuild --help to select a container and get its duebuild script's 
	help options directly.

--duebuild
:	Same behavior as --build, but a bit clearer that it is working with the
    selected container's duebuild script. One notable difference
    is that due --duebuild --help will select a container and execute
	duebuild --help to see the options provided by that particular script.

--dockerarg [arg]
:	Put [arg] in the docker run invocation. For multiple arguments, use
    multiple invocations of --dockerarg. This allows for things like 
	running containers with --privileged
	
--debug
:	Sets defaults of --username root --userid 0 and the --any option to show
images that were not created by DUE. Helpful for internal debug if image
creation dies running internal configuration scripts.

--container-name [name]
:	Change the name of the running container. This can provide clarity in a
 build automation environment, where containers may be automatically spun up.
 Note that if the new name does not have 'due' in it, it will be filtered
 out from DUE's --login option unless --all is also provided.
 This may or may not be desirable behavior.
 
--home-dir [host path]
:   Absolute path to a directory to use as the home directory
 when the user logs in. Defaults to the user's home directory unless overridden
 with this argument, or set otherwise in /etc/due/due.conf, or ~/config/due/due.conf

--mount-dir [hp:cp]
:	Mount absolute path on host system (hp) at absolute path in
 container. The colon (:) is necessary to separate the two. Multiple --mount-dir
 commands can be used in a single invocation.
 Example: mount host /tmp dir in container /var/build:  --mount-dir /tmp/:var/build

Logging in to a running container
-------
-l, --login
:	Choose an existing container to log in to.

--username  [username]
:	Name to use when logging in.

--userid    [id#]
:	User ID to use when logging in.

--groupname [groupname]
:	Container user's default group

--groupid   [id#]
:	ID of container user's group

--login-shell [path]
:	Program to use as login

--help-runtime
:	Invoke runtime help

--help-runtime-examples
:	Show examples of use

--create options
-------
These options are accessed after the --create argument, and,
predictably enough, relate to creating new images.


Creation Overview
-------

Containers created by DUE will always have files from ./templates/common-templates in
every image. The primary example of this is the **container-create-user.sh** script that sets up an
account for the user in the container, and allows commands to be run in the container as if
it was the user invoking them.

The order of creation is as follows, using the debian-package template as an example, where
the resulting image will be named 'debian-package-10'  

1 - The contents of common-templates are copied to a debian-package-10-template-merge directory under
    ./due-build-merge/  
2 - The contents of the debian-package template directory copied in to the 
    debian-package-10-template-merge directory and will overwrite any files with identical names.  
3 - Any REPLACE_ fields in the template files are replaced with values supplied from
    the command line (such as the starting container image)  and all files are copied to
	./due-build-merge/debian-package-10  
4 - The ./due-build-merge/debian-package-10/Dockerfile.create file is used to create the image
    from this build directory. 

Creation tips
-------

Quick image changes can be made by editing the build directory ( ./due-build-merge/debian-package-10 )
and re running ./due --create --build-dir ./due-build-merge/debian-package-10

The final image will hold a /due-configuration directory, which holds everything that went into the image.
This is very useful for install script debug inside the container.

A list of available default configurations is provided by running:
due --create --help
This will parse the README.md files under the ./templates directory looking for specific strings.
This output can be filtered by using wildcard syntax as follows:
due --create --help --filter <term>

Advanced image creation
-------

DUE 2.4.0 introduced hierarchical template parsing, where a template could be a
combination of files provided by 'sub-type' directories, to reduce file duplication.
With this, files with identical names and paths will overwrite the ones provided
by higher directories.

Example:
Given directory structure:
due/templates/foo/sub-type/bar/sub-type/baz

Image creation using the 'baz' template will be:
1 - files from templates/common-templates
2 - plus files from foo overwriting any files with the same relative path from common-templates
3 - plus files from bar overwriting foo files the same way
4 - plus files from baz overwriting bar files the same way.

While not normally needed, this may be useful for supporting a number of Images with minor but important differences.
See templates/README.md for more information.


Creation example
-------

1 - Configure an image build directory under due-build-merge named from --name
Mandatory:

--from [name:tag]
:	Pull name:tag from registry to use as starting point for the image.

--use-template [role]
:	Use files from templates/[role] to generate the config directory.

--description "desc"
:	Quoted string to describe the container on login.

--name [name]
:	Name for resulting image and config directory.
    Ex: debian-stretch-build, ubuntu-18.04-build, etc

Optional:

--prompt [prompt]
:	Set in container prompt to [prompt] to provide user context

--no-image
:   With --create, allow directories to be created, but do not try
    to build the image. Effectively stops use of --dir.
	Useful for debugging directory configuration issues.

--filter [term]
:   With --create --help, filter examples to contain [term].

2 - Build a Docker image from the image build directory.

--dir [dirname]
:	  Build using an existing configuration directory.

--clean
:	  Delete the due-build-merge staging directories.


--manage options
-------
These options are accessed after the --manage argument, and can
make working with containers/images easier.

-l,  --list-images
:	 List images created by DUE.

--stop <pattern>
:	 Use the menu interface to stop a running container. Works with
     --all to show containers not started by the user.
	 If <pattern> is supplied, it will match all the user's containers
	 to that pattern and produce a script that can be edited and run
	 to delete the listed containers.
	 NOTE: --all --stop <pattern> can be used to do some serious damage.
	 NOTE: since all DUE containers are started with -rm, stopping
	 a container deletes it and all the data in it from memory.

--export-container [name]
:    Export a running container to disk as a Docker image named name.
     Note that to run the saved image it must be added
	 back to the system with --import.

--export-image [name]
:    Save an existing Docker image as a file that can be
     copied elsewhere. If name is not supplied, the
	 user can choose from a menu.

--import-image [name]
:    Import a docker image stored on disk as tar file <name>

--copy-config
:    Create a personal DUE configuration file in ~/.config/due/due.config

--make-dev-dir [dir]
:    Populate a local directory for DUE container development.

--list-templates
:    List available templates.

--delete-matched [term]
:    Delete containers that contain this term. USE WITH CAUTION!

--docker-clean
:    Run 'docker system prune ; docker image prune' to reclaim disk space.

--help-examples
:	Examples of using management options.


FILES
=====

*/etc/due/due.conf*

:   Global configuration file

*~/.conf/due/due.conf*

:   Per-user default configuration file. Overrides the global one.
    `due --manage --copy-config` will set that up for the user.



ENVIRONMENT
===========
The configuration file sets up the following variables:

`DUE_ENV_DEFAULT_HOMEDIR` - evaled to define the user's home directory.
This can be useful if there is a naming convention for work directories
on shared systems, or your home directory is an NFS mount (which can create  
strange behavior when mounted in Docker) or you need to use a bigger build directory.

`DUE_USER_CONTAINER_LIMIT` - limit the number of containers a user
is allowed to run. Handy on a shared system to remind people of 
what they have running. This can easily be circumvented, though. 

BUGS
====

See GitHub Issues: [https://github.com/[CumulusNetworks]/[DUE]/issues]

AUTHOR
======

Alex Doyle <adoyle@nvidia.com>

COPYRIGHT
=========
SPDX-License-Identifier:     MIT

Copyright (c) 2019,2020 Cumulus Networks, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.



SEE ALSO
========

**due.conf(4)**
