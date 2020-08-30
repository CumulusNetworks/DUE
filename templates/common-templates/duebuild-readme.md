This file is a starting point for documenting the particulars of a container's duebuild script.  
See the debian-package version for what this might look like in practice.

# Duebuild for building REPLACE

The `duebuild` script handles setup and build for whatever target
the contiainer supports. As such this will vary from container to
container, but there are a set of standard arguments it is expected
to support defined by `common-templates/filesystem/usr/local/bin/duebuild`


# Workflow

This script is invoked by using the `--build` argument when running `due`.  
**Example:** build foo from source
`cd ./foo`
`due --build`


# Script help
The options for the REPLACE version of duebuild are printed below.  

To print the duebuild help for any build container without logging in to it, run:  
`due `--duebuild `--help  (select container)`

## duebuild --help  
**Usage**  : `duebuild: [--default|--cbuild|--build-dsc|--build-command]`  
  This script is a default run target for due `--build`.
  It performs build environment configuration before running one of the  
  build target commands.  

  **Build target commands.**  
      `--default`                Build with default settings: dpkg-buildpackage -uc -us -j(max)  
   `-c|--cbuild (args)`          Supply (args) to dpkg-buildpackage. If no args, build with defaults.
                                   This must be the last argument on the line as everything after is passed.  
      `--build-command (args)`   Do environment prep and run (args). Must be last argument on the line.  
      `--help-build-targets`     More detailed description of the above options.  
  
  **Build options:**  
   `-j|--jobs (#)`               Number of parallel builds to use. Defaults to the number of CPU cores.  
   `--use-directory (dir)`       cd to (dir) before trying to build.  
   `--prebuild-script (scr)`     Run script at container path (scr) before starting build. Pass 'NONE' to ignore.  
   `--script-debug`              Enable -x if passed as first argument.  
  
  **REPLACE build options:**  
  
  **More information:**  
   `--quiet`                    Suppress output.  
   `--verbose`                  More info.  
   `--help`                     This message  
   `--help-examples`            Print possible configurations.  
   `--version`                  Version of this script.  

 
## duebuild `--help-build-targets`  
  
duebuild use examples for specifying how to build Debian packages.  
  
In all these examples, duebuild will:  
 - REPLACE WITH DEFAULT SETUP 
 - And then apply the build command.  
  
 **Examples:**  
  DUE command:   `due --build`  
  duebuild runs: `duebuild --default` 
  Build command:  REPLACE  

  DUE command:   `due --build --cbuild`  
  duebuild runs: `duebuild --cbuild`  
  Build command:  REPLACE  

  DUE command:   `due --build --cbuild REPLACE WITH EXAMPLE ARGUMENTS`  
  duebuild runs: duebuild `--cbuild REPLACE WITH EXAMPLE ARGUMENTS`  
  Build command: REPLACE  
    
  DUE command:   `due --build --build-command make all`  
  duebuild runs: duebuild --build-command make all  
  Build command: make all  
  

## duebuild `--help-examples`  

duebuild examples of additional build options.  

** Examples: **

  Build.
   `./duebuild --cbuild` 
  
  Build default - a simple/standard build case.  
   `./duebuild --cbuild --default`  
  Pass additional arguments to build.  
   `./duebuild --cbuild  REPLACE_THIS` build example  

