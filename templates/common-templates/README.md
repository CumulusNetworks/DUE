# common-templates directory 
This directory holds files that are installed in all DUE containers to provide
common functionality.  

Starting Docker image + **common-templates** + role specific configuration template = resulting DUE Docker image.

# Contents:
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
├── post-install-local                     *<-- directory for any local files requring post install (deb, rpm, etc)*  
└── pre-install-config.sh.template         *<-- run before any files have been copied to the image*  
└── pre-install-local                      *<-- directory for any local files requring pre install (deb, rpm, etc)*  

