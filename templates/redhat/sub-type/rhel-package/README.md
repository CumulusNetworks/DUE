# rhel-package template
Copyright 2022,2023 Nvidia Corporation.  All rights reserved.

Configure the image to build Red Hat packages.

## RedHat 9 build environment creation example
Create default RedHat 9 build environment with: ./due --create --platform linux/amd64    --name pkg-redhat-9-amd64      --prompt PKGRH9       --tag pkg-amd64-redhat-9      --use-template rhel-package      --from docker.io/redhat/ubi9                 --description "Red Hat Enterprise Linux 9"  

### Explanation of the above:
  * Use a RedHat 9 image as the starting point.
  * Use --platform to force the architecture, as images for different architectures have the same name.
  * Name it pkg-redhat-9
  * Tag it as pkg-redhat-9
  * Set the prompt in container to be PGKRH9 so the context is (more) obvious
  * Merge in the files from ./templates/redhat/sub-type/rhel-package when creating the configuration directory
  * This will include files from the ./templates/redhat directory as well.

## RedHat 9 arm64 build environment creation example:
Create default RedHat 9 package build environment with: ./due --create --platform linux/aarch64  --name pkg-redhat-9-arm64      --prompt PKGRH9-arm64 --tag pkg-arm64v8-redhat-9    --use-template rhel-package      --from docker.io/redhat/ubi9                 --description "Red Hat Enterprise Linux 9"  

