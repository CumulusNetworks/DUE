# fedora-package template
Copyright 2022,2023 Nvidia Corporation.  All rights reserved.

Configure the image to build Red Hat Fedora packages.

## Fedora 41  build environment creation example:
Create default Fedora 41 build environment with: ./due --create --platform linux/amd64    --name pkg-fedora-41-amd64     --prompt PKGF41       --tag pkg-fedora-41-amd64     --use-template fedora-package    --from fedora:41                             --description 'Fedora 41'  


### Explanation of the above:
  * Use a fedora 41 image as the starting point.
  * Use --platform to force the architecture, as images for different architectures have the same name.
  * Name it pkg-fedora-41-amd64
  * Tag it as pkg-fedora-41-amd64
  * Set the prompt in container to be PGKRF-41 so the context is (more) obvious
  * Merge in the files from ./templates/redhat/sub-type/fedora-package when creating the configuration directory
  * Since this is a sub-type, files from ./templates/redhat will be included as well.


## Fedora 41 arm64 build environment creation example:
Create default Fedora 41 build environment with: ./due --create --platform linux/arm64    --name pkg-fedora-41-arm64     --prompt PKGF41-arm64 --tag pkg-fedora-41-arm64     --use-template fedora-package    --from fedora:41                             --description 'Fedora 41'  
