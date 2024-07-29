# Example template
Copyright 2022-2024 NVIDIA Corporation.  All rights reserved.

Use this as a starting point for any container development. Replace the EXAMPLE strings and update text as necessary.

It has also become a collection point for base image issues one should be aware of before using them to, say, create a build environment.  
For example, older Debian images require a patch to their repository files to build nowadays, and Ubuntu 24.04 has introduced an `ubuntu` user with ID 1000 that will probably conflict with a user account on the host system.  

This image is configured to EXAMPLE

## EXAMPLE creation
The use of debian:12 here is arbitrary. Any Debian based operating system Docker image will do.  
**NOTE** DUE parses these README.md files looking for lines that start with Create to use in the command line help.  
You'll want to make sure your template follows this convention.

Create default Debian EXAMPLE with: ./due --create --platform linux/amd64    --name example-debian-12       --prompt ExD12        --tag example-debian-12       --use-template example           --from debian:12                             --description 'Debian 12 example'  

### Explanation of the Debian example  above:
  * Use a Debian 12 image
  * Name it example-debian-12
  * Tag it as example-debian-12
  * Set the user's PS1 prompt in the image to be Ex so the context is (more) obvious
  * Merge in the files from ./templates/example when creating the configuration directory

# Image quirks
While most images will behave themselves with DUE, some require a little extra attention to function properly.  
Those images and their corrective action should be listed here.

## 1 - Old Debian images cannot Apt update  
...due to the repositoires moving. This can be worked around by applying patches to the container's `/etc/apt/sources*` directory, as follows:  

Create patched Debian 9 EXAMPLE with: ./due --create --platform linux/amd64    --name example-debian-9        --prompt ExD9         --tag example-patch-debian-9  --use-template example           --from debian:9                              --description 'Debian 9 with patch'                    --image-patch debian/9/filesystem

Create patched Debian 8 EXAMPLE with: ./due --create --platform linux/amd64    --name example-debian-8        --prompt ExD8         --tag example-patch-debian-8  --use-template example           --from debian:8                              --description 'Debian 8 with patch'                    --image-patch debian/8/filesystem

### Explanation of the --image-patch Debian examples above:
  * Arguments are the same as Debian 12
  * ...but --image-patch applies updates to the container from DUE's image-patch/debian/9/ directory before template code runs.
  * Currently this is needed to update the image's Apt repositories archived versions.

## 2 - Ubuntu 24.04 has an `ubuntu` user with ID 1000  
This image comes with an `ubuntu` user with ID **1000**, which, if that happens to be your ID,breaks the addition of your account in the container.  
Since it is unclear if there's something special about a pre-existing account DUE will not try to "get clever", but will intentionally throw   
an error and allow the user to decide what the proper course of action is.  
Options include:  
    1. Stealing the identity of the ubuntu account, by invoking due with  
        * `due --run --username ubuntu`  
    2. Using a different user ID when logging in to the container, with  
        * `due --run --userid 1001`  
    3. Update the  
        * `post-install-config.sh.template` to delete or reassign the user.  

# Use

## Build as yourself

You can use `due --run`  and select the image built in the previous step, which will:

1.  Mount your "home" directory ( this doesn't have to be your host's ~/ - see `docs/GettingStarted.md` )
2.  Create an account for you in the container, with your username and user ID.
3.  Source a .bashrc, and allow access to any other . files.
4.  ...and now you can navigate to your build directory, to build from the command line.  

## Build without interaction

There are a number of ways to use the container to build EXAMPLE  without logging in
to the container.

See `DUE/docs/Building.md` for additional information.

Start by: cd -ing to your build directory
DUE will auto-mount the current directory if it is running a command rather than a login.

Then try one of the following:

### Using `--command`
**Purpose:** execute everything after --command in a Bash shell.  
**Description:** Here the container executes everything after `--command` in a Bash shell.  
**Example:** due --run --command EXAMPLE_COMMAND_LINE_BUILD_COMMAND

**NOTES:**
1.  The **\;** used to separate the two commands to be run in the container. Without the **'\'**,
the invoking shell will interpret everything after the **';'** as a command to be run _after_ invoking DUE.
This can create confusion and complicate debugging as it will not be obvious the second command is failing outside of the container.


### Using `--build`
**Purpose:** Use container's `duebuild` script to perform additional configuration.  
**Description:** Here, `--build` is a shortcut to invoke the `/usr/local/bin/duebuild` script in the container, and provide
a bit of abstraction so as to not bother the user with the details of the build.  
**Tip:** get help for the container's `duebuild` script by running: `due --run --build help`

#### Using `--build --default`
**Purpose:** This will build a target that should always work to sanity check the build environment.  
**Description:** This will vary based on the role of the image, but in the case of EXAMPLE it will build EXAMPLE_BUILD_TARGET

#### Using `--build --cbuild`
**Purpose:** The `--cbuild` option allows for default configuration of the environment before build
**Example:** due --run --build --cbuild EXAMPLE_COMMAND_LINE_BUILD_COMMAND


#### Using additional duebuild arguments for EXAMPLE
Here the duebuild script can provide some convenience in the build by specifying the build
details as arguments that get passed to build
It's just another way of arriving at the final makefile invocation, however.

**Example:** due --run --build --jobs 4 EXAMPLE_ARGUMENTS_HANDLED_BY_THIS_DUEBUILD

## Debugging
Or, a descriptive collection of ways things have failed. Expect this list to grow.  


#  Additional notes:
None.


