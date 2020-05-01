# debian-package

Create an image that is configured for building Debian packages.

## Debian 10 build environment creation example
Create default Debian 10 build environment with: ./due --create --from debian:10    --description "Package Build for Debian 10" --name package-debian-10 --prompt PKGD10 --tag package-debian-10 --use-template debian-package  

### Explanation of the above:
  * Use a Debian 10 container (though ubuntu:18.04 works nicely as well (see below))
  * Name it package-debian-10
  * Tag it as package-debian-10
  * Set the prompt in container to be PGKD10 so the context is (more) obvious
  * Merge in the files from ./templates/debian-package when creating the configuration directory

## Debian 10 armel build environment creation example
Create default Debian 10 build environment with: ./due --create --from arm32v5/debian:10    --description "Package Build for arm32v5/Debian 10" --name package-armel-debian-10 --prompt PKGD10-arm --tag package-armel-debian-10 --use-template debian-package  

## Debian Sid (unstable)  build environment image creation example:
Create default Debian Sid  Debian package build environment with: ./due --create --from debian:sid   --description "Package Build for Debian Unstable" --name pkg-sid --prompt PKGSid --tag pkg-sid --use-template debian-package

## Ubuntu 18.04 build environment image creation example:
Create default Ubuntu 18.04 Debian package build environment with: ./due --create --from ubuntu:18.04 --description "Package Build for Ubuntu 18.04" --name pkg-u-18.04 --prompt PKGU1804 --tag pkg-ubuntu-18.04 --use-template debian-package

## Additional configuration
Apart from the expectedly unique `duebuild` and install scripts, there is no additional configuration.

# Use

## Build as yourself

You can use `due --run`  and select the image built in the previous step, which will:

1.  Mount your "home" directory ( this doesn't have to be your host's ~/ - see `docs/GettingStarted.md` )
2.  Create an account for you in the container, with your username and user ID.
3.  Source a .bashrc, and allow access to any other . files.
4.  ...and now you can navigate to your build directory, to build from the command line.  


## Build without interaction
There are a number of ways to use the container to build a Debian package without logging in
to the container.

See DUE/docs/Building.md for additional information.

Start by: cd -ing to the top level package directory ( such that running `ls ./debian/control` will succeed.)
DUE will auto-mount the current directory if it is running a command rather than a login.

Then try one of the following:
   

#### Using --command
**Purpose:** execute everything after --command in a Bash shell.  
**Description:** Here the container executes everything after `--command` in a Bash shell.  
**Example:** due --run --command sudo mk-build-deps --install --remove ./debian/control --tool \"apt-get -y\" \; dpkg-buildpackage -uc -us

**NOTES:**
1.  The **\;** used to separate the two commands to be run in the container. Without the **'\'**,
the invoking shell will interpret everything after the **';'** as a command to be run _after_ invoking DUE.
This can create confusion and complicate debugging as it will not be obvious the second command is failing outside of the container.


#### Using --build
**Purpose:** Use container's `duebuild` script to perform additional configuration.  
**Description:** Here, `--build` is a shortcut to invoke the `/usr/local/bin/duebuild` script in the container, and provide
a bit of abstraction so as to not bother the user with the details of the build.

**Tip:** get help for the container's `duebuild` script by running: `due --run --build help`

#### --build --default
**Purpose:** This will build a target that should always work to sanity check the build environment.  
**Description:** This will run `duebuild` to resolve and install all build dependencies for the package
in the current directory, and then execute a `dpkg-buildpackage -uc -us` to produce deb(s) in the
directory above the one where the build is being run.  

**Example:** due --run --build --default

#### Build a Debian package from source using a .dsc file
Given a compressed tar file and a Debian Source Code (dsc) file, DUE will configure the source directories and attempt to build.
**Example:** due --run --build --build-dsc foo.dsc

#### Using `--build --cbuild`
**Purpose:** The `--cbuild` option runs any default `duebuild` configuration (ex: dependency resolution ) and then passes subsequent arguments to dpkg-buildpackage 
**Example:** build just the source package: due --run --build --cbuild -us -uc --build=source


### Building a Debian package with different arguments
Here the duebuild script can provide some convenience in the build by specifying the build
details as arguments that get passed to build.
It's just another way of arriving at the final makefile invocation, however.

**Example:** Edit the debian/changelog to set a development version string for the package:
  due --run --build --dev-version ~123 --cbuild

## Debugging
Or, a descriptive collection of ways things have failed. Expect this list to grow.  


#  Additional notes:
None.




