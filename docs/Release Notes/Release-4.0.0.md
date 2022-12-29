Changes for the 4.0.0 release of Dedicated User Environment
------------------------------------------------------------

Licensing
----------
All files have been updated with Nvidia copyright messages, to reflect
Nvidia's acquisition of Cumulus Networks.

New features
------------
Support for Red Hat and SUSE based containers, with an RPM duebuild script.  
Support for running on Red Hat, SUSE, and Windows Subsystem for Linux hosts.  

Added --run --entrypoint override option to allow for interactive container debug.  
Added --run --platform to specify the architecture of the Docker image.  

Image builds now use a directory inheritance model to reduce file duplication.  
 Image build targets can be put in to sub directories, such that files in the parent
 directories are shared among build targets, and files in lower directories can overwrite them
 to create a particular image. The rhel-package and fedora-package targets building with
 a common duebuild script for RPMs in the file system directory under the templates/redhat
 directory is an example of this.  

The user's ~/.config/due/due.conf can have customized default arguments for
 container launch, if the sysadmin allows it. Always mounting a particular host directory
 when running a container would be one example of how this saves typing.  

Internal build
--------------
Makefile supports Debian packaging on debian/master or debian-test.  
Makefile adds conditional logic to be inactive during package build.  

Documentation updates
---------------------
FAQ.md - added for RPM/Podman references.  
Docs - updated Building.md.  
Troubleshooting.md - mentioned systemd-binfmt to close out Issue #39.  
docs/DUEAndWSL.md - Initial commit to document issues found during install.  
Added Release Notes directory to elaborate on changes.  

Runtime
-------
Due now prints sourced file paths if DUE is being run locally, for clarity.  
due-bashrc now does not export $PS1 any more, as that could cause inconsistent behavior.  
pipefail was added to identify the source of a failure.  

