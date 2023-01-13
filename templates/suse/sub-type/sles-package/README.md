# sles-package template
Copyright 2022,2023 Nvidia Corporation.  All rights reserved.

Configure the image to build Suse Linux Enterprise Server packages.

## SUSE SLES 15 build environment creation example
Create default SLES 15 build environment with: ./due --create --platform linux/amd64    --name pkg-sles-15-amd64       --prompt PKGS15       --tag package-sles-15         --use-template sles-package      --from registry.suse.com/bci/bci-base:latest --description "SUSE Linux Enterprise Server"  

### Explanation of the above:
  * Use a SLES 15 image as the starting point.
  * Use --platform to force the architecture, as images for different architectures have the same name.
  * Name it package-sles-15-amd64
  * Tag it as package-sles-15
  * Set the prompt in container to be PGKS15 so the context is (more) obvious
  * Merge in the files from ./templates/suse/sub-typesles-package when creating the configuration directory
  *  As it is a sub type, files from ./templates/suse will be added as well.
  
## SUSE SLES 15 arm64 build environment creation example:
Create default SLES 15 Debian package build environment with: ./due --create --platform linux/aarch64  --name pkg-sles-15-arm64       --prompt PKGS15-arm64 --tag pkg-sles-15-arm64       --use-template sles-package      --from registry.suse.com/bci/bci-base:latest --description "SUSE Linux Enterprise Server"  

