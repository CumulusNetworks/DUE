# Template directory README

This directory holds specific container configurations.
Note that each sub directory also contains a README.md with
specific information about the contents of that directory.

# Current configurations:

|                                                  |   |
|------------------------------------------------- |---|
|[common-templates](./common-templates)            |- Files common to all DUE images|
|[example](./example)                              |- The bare minimum of DUE build infrastructure. A good starting point for new templates.|
|[debian-package](./debian-package)                |- Tools for Debian package build|
|[ONIE](./onie)                                    |- Build the Open Network Install Environment|
|[frr](./frr)                                      |- Build the Free Range Routing package|
|[sles-package](./suse/sub-type/sles-package)      |- SUSE Enterprise Linux Server build environment base image|
|[opensuse-package](suse/sub-type/opensuse-package)|- OpenSUSE build environment base image|
|[rhel-package](redhat/sub-type/rhel-package)      |- Red Hat Enterprise Linux base image |
|[fedora-package](redhat/sub-type/fedora-package)  |- Fedora build environment base image|



# Create a Docker image from these templates
The easiest was to do this is to:  
  1. Run `./due --create --help`  
  2. Cut and paste an example command to create an image.   


**NOTE** Using the leading `./` has DUE parse all the README.md files in the local templates directory to get examples.  
Without the `./` the version of DUE installed in your system will be used instead (if it has been installed.)  
  
## Example:  Create a Debian package build container  
**Run:**  
`./due --create --from debian:10    --description "Package Build for Debian 10" --name package-debian-10 --prompt PKGD10 --tag package-debian-10 --use-template debian-package`  
  
**This:**  
1. Uses the `debian:10` Docker image file from DockerHub as a starting point.  
2. Implicitly adds in the contents of the **common-templates** directory to the image to provide features like the script that creates a user account in the container on login.  
3. Uses the contents of the **debian-package** template directory to configure the image.  
4. Sets the image name, tag and description.  
5. Sets the default shell prompt in the container to be `PKGD10` as a hint at run time to let the user know they are in a package build container for Debian 10.  

### To look at those steps from a different perspective:

### Start with:  
A **base image** of Debian 10, downloaded from Dockerhub

### Then add:
The contents of the **common** templates directory:

├── Dockerfile.config    *<-- Docker Labels to provide hints for running the container*  
├── Dockerfile.template  *<--framework of steps in image creation*  
├── filesystem  
│   ├── etc  
│   │   ├── DockerLoginMessage.template  *<--container log in message to provide the user some context*  
│   │   └── due-bashrc.template          *<-- set container prompt for another context hint*  
│   └── usr  
│...... └── local  
│.........└── bin  
│............└── container-create-user.sh  *<-- create user account in container that matches host. Also used for running commands without login.*  
├── install-config-common-lib.template     *<-- DUE image assembly utilities*    
├── post-install-config.sh.template        *<-- run after file copy to image *  
└── pre-install-config.sh.template         *<-- run before any files have been copied to the image*

### Then add:
The contents of the **debian-package** template directory:

├── Dockerfile.config  *<-- runtime hints (mount parent directory when running container)*  
├── filesystem  
│.. └── usr  
│...... └── local  
│........ └── bin  
│........... └── duebuild  *<-- script DUE runs to build by default *  
├── post-install-config.sh.template  *<-- install Debian build specific packages *  
└── README.md  *<-- describe container and its duebuild script*  

### Which creates:
A Debian 10 package **build image** for Docker.


# Create your own templates

 1. Copy the **example** template directory, or a related template directory and rename it.  
 2. Edit the `README.md` to reflect what your new image will do.  
 3. Make sure to edit the lines starting with `Create` to provide default examples
     that will be listed when 'due --create help' is run  
 4. And, of course, edit and add files as necessary.  

**TIP** You can use relative pathed soft links to reference other files under the `templates` directory. The frr build has a somewhat arbitrary example of this for the debian-package `duebuild` script. This can be useful if you have templates that share common code.  

# Advanced - Template sub types

If you find you are creating many templates with minor differences, you can use **`sub-type`** directories to implement
a kind of class inheritance to reduce file repetition. Each `sub-type` directory supplies additional files to be
added to the merge directory the container is created out of. 

**Note:** it is still possible to reduce file duplication by having relative soft links between template directories. The files the links reference will get copied in just fine.

## Practical Example
See the [redhat](./redhat) and [suse](./suse) directories for sub-types.  


## Abstract Example
Given a directory path:  
  `due/templates/foo/sub-type/bar/sub-type/baz`  
  Where:  
  *    **foo:** has files A and B  
  *    **sub-type:** only contains types of images  
  *    **bar:** has files B and C  
  *    **sub-type** only contains types of images  
  *    **baz:** has files B and D  
	
	When specifying `--use-template baz`  
	...the build code will go searching for it, and copy files from every directory that is **not** `sub-type` in the path to the target template. Those files will be copied in to the merge directory from top to bottom, so that the merge directory will have:
  * 	A - supplied by foo, as nothing overwrote it
  * C - supplied by bar
  * B - supplied by baz. Bar overwrote the copy supplied by foo, but baz was processed last, and its copy overwrote the others.
  * D - supplied by baz.  
  
This is a bit much for a small number of containers, but if you have a proliferation case, where different releases may be accessing release specific components in a local repository. Here is a less abstract configuration:

## Less Abstract Example
  Two directories:  
  * /templates/alpha-release/sub-type/package-build/sub-type/developer-env 
  * /templates/alpha-release/sub-type/package-build/sub-type/release-env  
  * /templates/alpha-release/sub-type/firmware-build/sub-type/developer-env  
  * /templates/alpha-release/sub-type/firmware-build/sub-type/release-env  
Where: 
  * alpha-release has repository keys for alpha release.  
  * package-build has additional tools for building packages.  
  * firmware-build builds firmware binaries using packages from the alpha-release repository.  
  * ...and developer/release-env hold sources.list files to release and developer package repositories.  



 
  

