# debian-package

Build a Debian package

## Notes:
This is a container with Debian package tools

This comes with a script - `dpkg-plus`, which tries to emulate some of the
functionality of sbuild. See it's --help for more information.


## Suggested configuration:
	Use a debian 10 container (though ubuntu:18.04 works nicely as well)
	name it package-debian-10
	tag it as package-debian-10
	set the prompt in container to be PGKD10 so the context is (more) obvious
	merge in the files from ./templates/debian-package when creating the configuraton direcotry

## Image creation example for a Debian Buster build environment.
<br>
Create default Debian 10 build environment with: ./due --create --from debian:10 --description "Package Build for Debian 10" --name package-debian-10 --prompt PKGD10 --tag package-debian-10 --use-template debian-package
<br>

## Image creaton example for an Ubuntu 18.04 build environment.
<br>
Create default Ubuntu 18.04 Debian package build environment with: ./due --create --from ubuntu:18.04 --description "Package Build for Ubuntu 18.04" --name pkg-u-18.04 --prompt PKGU1804 --tag pkg-ubuntu-18.04 --use-template debian-package


## Use

### Build as yourself

You can use `due --run`  and select the container built in the previous step, which will
mount your home directory, and allow you to work in the container, provided ONIE is checked out in your home directory.


### Build without interaction
DUE allows commands to be run in a container, so if you want to just build a Debian package
without having to log in to the container (and assuming due-package-debian-10 is the name of your Debian build contianer)
<br>
1. cd to the top level of the package directory ( Hint: ls ./debian/control should succeed )
<br>
2. 	If all the build dependencies are already in the container, run:
<br>
.. `due --run --image due-package-debian-10 --command dpkg-buildpackage -uc -us`
or, if you are typing averse...
.. `due -r -i due-package-debian-10 -c dpkg-buildpackage -uc -us`
<br>
Or you can use a wrapper script that will resolve dependencies and do a few other things.
`./due --run --image due-package-debian-10 --command /usr/local/bin/dpkg-plus --build`
<br>
**tip** get help with: `due --run --command /usr/local/bin/dpkg-plus --help`

<br>

If you checked out the DUE code from GitHub, you can test it by building DUE into a Debian Package. 
For example, if you built the Ubuntu image above you can:
1. cd to the top level DUE directory ( such that running ls ./debian/control will succeed.)
2. Run: ./due --run-image due-pkg-u-18.04 --command /usr/local/bin/dpkg-plus --build

   
