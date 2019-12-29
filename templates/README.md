This directory holds specific container configurations.
Note that each subdirectory also contains a README.md with
specific information about the contents of that directory.

Current configurations:
common-templates - Configuration required for all DUE images

debian-packge    - Tools for Debian package build

ONIE             - build the Open Network Install Environment

frr              - build the Free Range Routing package

example          - Puts just DUE build infrastructure in place.
                   Copy and use as a starting point for new images.
				   
USE:
Create a configuration directory from the template.

Workflow:
 ./due --create <specify base container, name it, etc > --template-dir <directory name>-template
 ./due --create --dir <name of dir>
 
Example: Creating a debian package build container

At the moment, the debian-package template directory looks like:
├── Dockerfile.config
├── filesystem
│   └── usr
│       └── local
│           └── bin
│               └── dpkg-plus
├── post-install-config.sh.template
└── README.md

Compared to the common templates directory:
├── Dockerfile.config
├── Dockerfile.template
├── filesystem
│   ├── etc
│   │   ├── DockerLoginMessage.template
│   │   └── due-bashrc.template
│   └── usr
│       └── local
│           └── bin
│               └── container-create-user.sh
├── post-install-config.sh.template
└── pre-install-config.sh.template

...so the customization here is:
	**dpkg-plus** gets added to /usr/local/bin/ on the container (its my wrapper script for Debian builds)
	**post-install-config.sh.template** adds packages specific to package building and in-container development
	**Dockerfile.config** supplies default paramteters that suggest how DUE should run it.

To create this:
  
./due --template --generate-template debian-packge
  ...which creates a debian-package-template directory
  
./due --create --from debian:buster --description "Buster Build container" --name busterbuild --prompt D10build --tag buildenv-debian --template-dir debian-packge-template
  ...Here we specify:
     debian:buster is the Docker image to start with
	 Buster Build container will be it's description
	 busterbuild is the image name, and the name of the directory to put the configuration in
	 D10build will be the cursor prompt in the container (makes it easier to establish context)
	 buildenv-debian is the Docker image tag
	 and pull all the configuration files from debian-package-template
	 
./due --create --dir busterbuild
  ...Get Docker to create the image using the configuration directory busterbuild

