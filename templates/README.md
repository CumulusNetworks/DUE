# Template directory README

This directory holds specific container configurations.
Note that each subdirectory also contains a README.md with
specific information about the contents of that directory.

# Current configurations:
**common-templates** - Files common to all DUE images

**debian-packge**    - Tools for Debian package build

**ONIE**             - build the Open Network Install Environment

**frr**              - build the Free Range Routing package

**example**          - The bare minimum of DUE build infrastructure. A good starting point for new templates.

# Create a Docker image from these templates
The easiest was to do this is to:  
  1. Run `./due --create help`  
  2. Cut and paste an example command to create an image.   


**NOTE** Using the leading `./` has DUE parse all the README.md files in the local templates directory to get examples.  
Without the `./` the version of DUE installed in your system will be used instead (if it has been installed.)  
  
##Example  Create a Debian package build container
Run  
`./due --create --from debian:10    --description "Package Build for Debian 10" --name package-debian-10 --prompt PKGD10 --tag package-debian-10 --use-template debian-package`  
  
This:  
1. Uses the `debian:10` Docker image file from DockerHub as a starting point.  
2. Implicitly adds in the contents of the **common-templates** directory to the image to provide features like the script that creates a user account in the contianer on login.  
3. Uses the contents of the **debian-package** template directory to configure the image.  
4. Sets the image name, tag and description.  
5. Sets the default shell prompt in the container to be `PKGD10` as a hint at runtime to let the user know they are in a package build container for Debian 10.  

### Base image of Debian 10  

#### + Plus +

### Contents of the common templates directory:
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

#### + Plus +

### Contents of the debian-package template directory:  
├── Dockerfile.config  *<-- runtime hints (mount parent directory when running container)*  
├── filesystem  
│.. └── usr  
│...... └── local  
│........ └── bin  
│........... └── duebuild  *<-- script DUE runs to build by default *  
├── post-install-config.sh.template  *<-- install Debain build specific packages *
└── README.md  *<-- describe container and its duebuild script*  


#### = Equals =

### Debian 10 package build environment.


# Create your own templates

 1. Copy the **example** template directory, or a releated template directory and rename it.  
 2. Edit the `README.md` to reflect what your new image will do.  
 3. Make sure to edit the lines starting with `Create` to provide default examples
     that will be listed when 'due --create help' is run  
 4. And, of course, edit and add files as necessary.  

**TIP** You can use relative pathed soft links to reference other files under the `templates` directory. The frr build has a somewhat arbitrary example of this for the debian-packge `duebuild` script. This can be useful if you have templates that share common code.  



  

