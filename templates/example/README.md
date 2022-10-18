# example template
Use this as a starting point for any container development. Replace the EXAMPLE strings and update text as necessary

This image is configured to EXAMPLE

## EXAMPLE creation
The use of debian:10 here is arbitrary. Any Debian based operating system Docker image will do.  
**NOTE** DUE parses these README.md files looking for lines that start with Create to use in the command line help.  
You'll want to make sure your template follows this convention.

Create default Debian EXAMPLE with: ./due --create --platform linux/amd64    --name example-debian-10       --prompt ExD10        --tag example-debian-10       --use-template example           --from debian:10                             --description "Debian 10 example"  

### Explanation of the Debian example  above:
  * Use a Debian 10 image
  * Name it example-debian-10
  * Tag it as example-debian-10
  * Set the user's PS1 prompt in the image to be Ex so the context is (more) obvious
  * Merge in the files from ./templates/example when creating the configuration directory

## Additional configuration
This lists changes that are unique to this container.

EXAMPLE

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


