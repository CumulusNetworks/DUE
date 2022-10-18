# opensuse-package template

Configure the image to build opensuse packages.

## openSUSE leap build environment creation example
Create default openSUSE leap build environment with: ./due --create --platform linux/amd64    --name pkg-opensuse-leap-amd64 --prompt PKGoS        --tag pkg-opensuse-leap-amd64 --use-template opensuse-package  --from opensuse/leap                         --description "openSUSE leap"  

### Explanation of the above:
  * Use an opensuse/leap image as the starting point.
  * Use --platform to force the architecture, as images for different architectures have the same name.
  * Name it pkg-opensuse-leap-amd64
  * Tag it as pkg-opensuse-leap-amd64
  * Set the prompt in container to be PKGoS so the context is (more) obvious
  * Merge in the files from ./templates/opensuse-package when creating the configuration directory
  *  As it is a sub-type, files from ./templates/suse will be added as well

## openSUSE 15 arm64 build environment creation example
Create default Suse 15 build environment with: ./due --create --platform linux/aarch64  --name pkg-opensuse-leap-arm64 --prompt PKGoS-arm64  --tag pkg-opensuse-leap-arm64 --use-template opensuse-package  --from opensuse/leap                         --description "openSUSE leap"  

