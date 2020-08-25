#Building

There are a few ways to build using DUE.

##Build inside the container
This is the expected use case if you are debugging a build.  
1. Run due (if the code is not under your home directory, use the `--mount-dir` command to have the container mount it.)  
2. Select a build container.  
3. You are now logged in with your home directory mounted.  
4. cd to the build directory.  
5. Build as you normally would.  

##Build outside the container.
In this case, you'll invoke commands that run inside the container that do the build.  
This is the expected use case for code that you know builds, or automated build environments.

**Tip** Use the `--run-image image-name:image-tag` argument to skip the image selection menu if you already know which image and tag you want to run.

There are two options for running build commands in the container:

###The `--command` option, which allows for very specific invocations.  
1. Mounts the current directory in the container.  
2. Runs everything after `--command` in the container.  
3. Exits.  
**Example:** List working directory in the container, and print its path:  
 `due --run --command ls -l \; pwd`

###The --build option, which invokes `/usr/local/bin/duebuild` in the container.

The `duebuild` script provides the opportunity to simplify build configuration by performing mandatory steps and allowing the
user to just specify the optional ones.

There are two expected arguments and behaviors from the `duebuild` script:

**`--default`** - The script will try to do a build of the target with default settings. This can be as simple as 'make all' or 'dpkg-buildpackage -uc -us',
or more involved. The end goal is to produce a binary that showcases the software without user the user making decisions, if possible.

**`--cbuild <args>`** This takes the rest of the command line as <args> and passes it to whatever the default build mechanism is (make, dpkg-buildpackage, etc)

As build requirements may vary, other options may be present in the duebuild script to prepare the build environment, or post process the output.
For example, the user might want to change the version of a Debian package build to have a development string in it, or skip running tests if
they are doing debug builds. The duebuild script is a convenient place to handle this complexity.
See the existing duebuild scripts under the `templates` directory for examples of this.


##Practical build invocation examples

####Example: Build a Debian package

#####Using --command
due --run --command sudo mk-build-deps --install --remove ./debian/control --tool \"apt-get -y\" \; dpkg-buildpackage -uc -us

#####Using --build --default
due --run --build --default

#####Using --build --cbuild
due --run --build --cbuild -uc -us    
or  
due --run --build --cbuild -uc -b -j8


####Example: Building a Debian package with different arguments

#####Using --command
due --run --command sudo mk-build-deps --install --remove ./debian/control --tool \"apt-get -y\" \; dpkg-buildpackage -uc -b -j8

##### A failure using --build --default
due --run --build --default -b -j8
Unrecognized option [ -b ]. Exiting                                               
ERROR - /usr/local/bin/duebuild [ --default -b -j8 ] failed with return code [ 1 ]  
( Fails because default does not take other arguments, and would also still be supplying the '-us' anyway)





