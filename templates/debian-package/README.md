# debian-package template

Configure the image to build Debian packages.

## Debian 10 build environment creation example
Create default Debian 10 build environment with: ./due --create --from debian:10    --description "Package Build for Debian 10" --name package-debian-10 --prompt PKGD10 --tag package-debian-10 --use-template debian-package  

### Explanation of the above:
  * Use a Debian 10 container (though ubuntu:20.04 works nicely as well (see below))
  * Name it package-debian-10
  * Tag it as package-debian-10
  * Set the prompt in container to be PGKD10 so the context is (more) obvious
  * Merge in the files from ./templates/debian-package when creating the configuration directory

## Debian 10 armel build environment creation example:
Create default Debian 10 Debian package build environment with: ./due --create --from arm32v5/debian:10    --description "Package Build for arm32v5/Debian 10" --name pkg-armel-debian-10 --prompt PKGD10-arm --tag pkg-armel-debian-10 --use-template debian-package  

## Debian Sid (unstable)  build environment image creation example:
Create default Debian Sid  Debian package build environment with: ./due --create --from debian:sid   --description "Package Build for Debian Unstable" --name pkg-sid --prompt PKGSid --tag pkg-sid --use-template debian-package

## Ubuntu 20.04 build environment image creation example:
Create default Ubuntu 20.04 Debian package build environment with: ./due --create --from ubuntu:20.04 --description "Package Build for Ubuntu 20.04" --name pkg-u-20.04 --prompt PKGU1804 --tag pkg-ubuntu-20.04 --use-template debian-package

## Additional configuration
In addition to the the expectedly unique `duebuild` and install scripts, there is a script for managing local package repositories: `due-manage-local-package-repo.sh`. See below.


# Architecture  

## /usr/local/bin/duebuild
Every container built by DUE should come with its own `/usr/local/bin/duebuild` script.
This script contains utility functions to simplify common build tasks within the context of the container.  
While the functionality will vary by container purpose, there are some standard interfaces:  

  * due --build (or --duebuild) <- invoke a default build case that should build something to prove it works.  
  * due --duebuild --help <- print the command line help of the container's duebuild script.  
  * due --build --cbuild  <- takes everything after this as a literal string to pass to the build.  
  
Where this comes in handy is in reducing typing and performing default operations.  
In the case of the **debian-package** duebuild script, `due --build` will:  
  * apt-get update the container  
  * apt-get upgrade the container  
  * apt-get install all package dependencies read from the local debian/control  
  * run `dpkg-buildpackage -us -uc` with the maximum number of jobs (unless a different -jX has been passed)  
  
For additional options, you can run the duebuild help for a container with:  
`due --help --duebuild <select container> `

## /usr/local/bin/due-manage-local-repo.sh
A script for managing a local package repository. See its command line help for details, and  
**`Building a package that depends on previously built packages`** below.


# Use

## Build as yourself

You can use `due --run`  and select the DUE image, which will:

1.  Mount your "home" directory ( this doesn't have to be your host's ~/ - see `docs/GettingStarted.md` )
2.  Create an account for you in the container, with your username and user ID.
3.  Source a .bashrc, and allow access to any other . files.
4.  ...and now you can navigate to your build directory, to build from the command line.  


## Build without interaction
There are a number of ways to use the container to build a Debian package without logging in
to the container.  

See DUE/docs/Building.md for additional information.  
**Tip** Use the `--run-image image-name:image-tag` argument to skip the image selection menu if you already know which image and tag you want to run.  

Start by:  
 cd -ing to the top level package directory ( such that running `ls ./debian/control` will succeed.)


Then try one of the following:
   

#### Using --command
**Purpose:** run arbitrary commands in a container  
**Description:** Here the container executes everything after `--command` in a Bash shell.  
**Example:** `due --run --command sudo mk-build-deps --install --remove ./debian/control --tool \"apt-get -y\" \; dpkg-buildpackage -uc -us`

**NOTES:**  
1.  The **\;** is necessary to separate the two commands to be run in the container. Without the **'\'**,
the invoking shell will interpret everything after the **';'** as a command to be run _after_ invoking DUE.
This can create confusion and complicate debugging as it will not be obvious the second command is failing outside of the container.


#### Using --build
**Purpose:** Use container's `duebuild` script to perform additional configuration.  
**Description:** Here, `--build` is a shortcut to invoke the `/usr/local/bin/duebuild --default` script in the container, and provide
a bit of abstraction so as to not bother the user with the details of the build.

**Tip:** get help for the container's `duebuild` script by running: `due --help --duebuild <select container>`

#### Using --build --default
**Purpose:** This will build a target that should always work to sanity check the build environment.  
**Description:** This will run `duebuild` to:  
1. Upgrade all packages in the container.
2. Resolve and install all build dependencies for the package being built
3. Execute a `dpkg-buildpackage -b -us` to produce deb(s) in the directory above the one where the build is being run.  

**Example:** due --run --build --default

#### Build a Debian package from source using a .dsc file
Given a compressed tar file and a Debian Source Code (dsc) file, DUE will configure the source directories and attempt to build.
**Example:** due --run-image due-package-debian-10 --build-dsc foo.dsc
**Example:** due --duebuild --build-dsc foo.dsc

#### Using `--build --cbuild`
**Purpose:** The `--cbuild` option runs any default `duebuild` configuration (ex: dependency resolution ) and then passes subsequent arguments to dpkg-buildpackage 
**Example:** build just the source package: `due --run --build --cbuild -us -uc --build=source`


### Building a Debian package with different arguments
Here the duebuild script can provide some convenience in the build by specifying the build
details as arguments that get passed to build.
It's just another way of arriving at the final makefile invocation, however.

**Example:** Edit the debian/changelog to set a development version string for the package:
  `due --run --build --dev-version ~123 --cbuild`

### Adding `DEB_BUILD_OPTIONS`
**Purpose** Passing options that change the build, like `debug` or `nostrip`  
**Example** `due --build --deb-build-option debug --deb-build-option nostrip`

Specify one argument per `--deb-build-option` to have the duebuild script 
set the `DEB_BUILD_OPTIONS=` prior to running dpkg-buildpackage. You can confirm what 
was set by checking the build log output for the header that describes how 
dpkg-buildpackage was run.

### Building a package that depends on previously built packages
**Purpose** use a local package repository to store and serve built packages.  
**Example** ``due --run --build --use-local-repo myRepo``  
Or:  
**Example** ``due --run--image due-package-debian-10 --build --use-local-repo myRepo``  
Or:  
**Example** ``due --run-image due-package-debian-10 --build --use-local-repo myRepo --cbuild --build=binary --unsigned-changes``  


If just a repository name is passed, the ``--use-local-repo`` option will create a local
Debian package repository in the directory above the build directory.
If an absoulte path and name are passed, the repository will be created at that location as seen from the **container**.
Either way, this repository will get an entry in the container's sources.list.d/ and will have the highest priority.
If it does not already exist, duebuild will create it at the start of build, and add all built packages to it at the end of build.  
    
This is incredibly helpful when building packages that depend on other packages to have already been built.  
    
**For Example** - if package B depends on files supplied by package A  

`cd package-A`  

Now use a previously built Debian 10 image by default, and name the repository myRepo.  
`due --run--image due-package-debian-10 --build --use-local-repo myRepo`  

The duebuild script in the container  looks for `myRepo`, fails to find it, creates it, adds an /etc/apt/sources.list.d entry, 
and then accesses it, resulting in a few warnings because the repository isn't populated.  

The build completes and the package-A *.debs are put in `myRepo`  

`cd package-B`  

`due --run--image due-package-debian-10 --build --use-local-repo myRepo`  
The duebuild script sees the exising local package repository `myRepo` as a high priority repository and references it on apt-update.
The build proceeds, with the package-A *.debs being accessed.  
The build completes, and package-B debs are added to `myRepo`

For additional information about managing a local package repository,  
see the command line help for `/usr/local/bin/due-manage-local-repo.sh.`  

**Caveats**:
1 - If you supply an absolute path to the repository when invoking builds from outside
     the container, make sure that path exists from the **container's** execution context.	 
2 - There is some overlap here with the `--install-debs-dir` option.  
3 - Also this has only been tested with .debs of a single architecture. Using source tar files and multiple architectures may not work.

### Doing dependency install and running your own build command  
**Purpose** a finer level of control over dpkg-buildpackage, or anything else  
**Example** `./due --duebuild --build-command DEB_BUILD_OPTIONS="\'debug noopt\'" dpkg-buildpackage -b -j7`

If you want to fine-tune the build command, then this will do the container
upgrade and dependency installation, and then just run whatever follows 
`--build-command`.  
Note that `--build-command` must be the last argument, as everything after that
is passed through...and you may have to escape quote terms, as illustrated above.

## Debugging
If you get a build error that contains:
 `dpkg-source: aborting due to unexpected upstream changes`
 ... you have an existing source tar file above your build directory and you are trying ot build source
 - Override the default build configuration by adding `--cbuild --build=binary --unsigned-changes`
Ex: `due --run-image due-pkg-sid --build --cbuild --build=binary --unsigned-changes`
 

due --run-image due-pkg-sid --build --use-local-repo trepo --cbuild --build=binary -j8

due --run-image due-pkg-sid --build --use-local-repo trepo --cbuild --build=binary --unsigned-changes

### Enable debug in the duebuild script.
**Purpose** See exactly how the script in the container is interpreting things, without getting into it.  
**Example** due --duebuild --script-debug --cbuild  

#  Additional notes:

The `duebuild` script now defaults to just building unsigned package binaries, on the assumption that most users
downloading source will just want to build the binaries and be about their day.  
Previously it defaulted to building source as well, but this can fail if the original tar files are around,
and no changes have been made, breaking the objective of the default configuration to just produce soemthing useful.


