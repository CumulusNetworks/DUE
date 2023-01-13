# fedora-package template
Copyright 2022,2023 Nvidia Corporation.  All rights reserved.

Configure the image to build Red Hat Fedora packages.

## Fedora 36  build environment creation example:
Create default Fedora 36 build environment with: ./due --create --platform linux/amd64    --name pkg-fedora-36-amd64     --prompt PKGF36       --tag pkg-fedora-36-amd64     --use-template fedora-package    --from fedora:36                             --description "Fedora 36 "  


### Explanation of the above:
  * Use a fedora 36 image as the starting point.
  * Use --platform to force the architecture, as images for different architectures have the same name.
  * Name it pkg-fedora-36-amd64
  * Tag it as pkg-fedora-36-amd64
  * Set the prompt in container to be PGKRF-36 so the context is (more) obvious
  * Merge in the files from ./templates/redhat/sub-type/fedora-package when creating the configuration directory
  * Since this is a sub-type, files from ./templates/redhat will be included as well.


## Fedora 36 arm64 build environment creation example:
Create default Fedora 36 build environment with: ./due --create --platform linux/arm64    --name pkg-fedora-36-arm64     --prompt PKGF36-arm64 --tag pkg-fedora-36-arm64     --use-template fedora-package    --from fedora:36                             --description "Fedora 36 "  
