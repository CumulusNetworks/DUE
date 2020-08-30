# Duebuild for building Debian packages.

The `duebuild` script handles setup and build for whatever target
the contiainer supports. As such this will vary from container to
container, but there are a set of standard arguments it is expected
to support defined by `common-templates/filesystem/usr/local/bin/duebuild`


# Workflow

This script is invoked by using the `--build` argument when running `due`.  
**Example:** build package foo from source
`cd ./foo`
`due --build`

**Example:** build package foo from foo.dsc
`due --build --build-dsc foo.dsc`

# Script help
The options for the Debian package version of duebuild are printed below.  

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
      `--build-dsc (.dsc file)`  Build from debian source control file .dsc and associated tar.gz.  
  
  **Build options:**  
   `-j|--jobs (#)`               Number of parallel builds to use. Defaults to the number of CPU cores.  
   `--use-directory (dir)`       cd to (dir) before trying to build.  
   `--prebuild-script (scr)`     Run script at container path (scr) before starting build. Pass 'NONE' to ignore.  
   `--script-debug`              Enable -x if passed as first argument.  
  
  **Debian package build options:**  
   `--skip-tests`                Define DEB_BUILD_OPTIONS=nocheck before build.  
   `--deb-build-option (opt)`    Add 'opt' to DEB_BUILD_OPTIONS. Use once per option.  
   `--build-attempts (times)`    Try to build this many times. Default is [ 1 ]  
   `--dev-version (vers)`        Insert string into changelog package version for pre-release builds.
                                  Note: you need to supply the leading ~ or +  
   `--just-dev-version`          Exit after `--dev-version` applies  
   `--set-git-hash `             If building type Git, do not autodiscover, use passed hash.  
   `--source-date-epoch (d)`     Force the creation time of files, via date +%s. Otherwise defaults to now.  
   `--source-format-one`         Clear git source history from package and set source to build as 1.0  
   `--install-debs-dir (dir)`    Install all debs from (absolute path in container dir) before build.  
   `--add-sources-list (file)`   Container relative path to include sources.list in build dir.  
   `--use-local-repo (repo)`     Create a local package repository named (repo) to store and serve packages.  
                                If (repo) starts with a '/' it will be treated as a container-relative  
                                path for the location of the repository. Otherwise it defaults to the  
                                directory above the build area.  
  
  **More information:**  
   `--quiet`                    Suppress output.  
   `--verbose`                  More info.  
   `--help`                     This message  
   `--help-examples`            Print possible configurations.  
   `--version`                  Version of this script.  

 
## duebuild `--help-build-targets`  
  
duebuild use examples for specifying how to build Debian packages.  
  
In all these examples, duebuild will:  
 - Upgrade the container's packages.  
 - Install the package's build dependencies.  
 - And then apply the build command.  
  
 **Examples:**  
  DUE command:   `due --build`  
  duebuild runs: `duebuild --default` 
  Build command: dpkg-buildpackage -uc -us -j(max)  
  Note: to get the same outcome from the command line, run:  
    due `--run --command sudo apt-get update \; sudo apt-get upgrade \; sudo mk-build-deps --install --remove ./debian/control --tool 'apt-get -y' \; dpkg-buildpackage -uc -us -j(max)`  
  
  DUE command:   `due --build --cbuild`  
  duebuild runs: duebuild `--cbuild`  
  Build command: dpkg-buildpackage-uc -us -j(max)  
  
  DUE command:   `due --build --cbuild -b`  
  duebuild runs: duebuild --cbuild -b`  
  Build command: dpkg-buildpackage-b -j(max)  
  
  DUE command:   `due --build --build-command make all`  
  duebuild runs: duebuild --build-command make all  
  Build command: make all  
  

## duebuild `--help-examples`  

duebuild examples of additional build options.  

  `--cbuild` passes whatever args are after it directly to dpkg-buildpackage.  
  The following pulls from the dpkg-buildpackage man pages for two different versions.  

  So for example:  
  **--cbuild examples**. (versions earlier than 1.18.5, found in Jessie 8.)  
   ./duebuild `--cbuild takes:  
     -A - architecture independent (type 'all')  
     -B - architecture dependent (amd64, armel, etc)  
     -S - source only.  
     -b - architecture dependent, independent, and no source.  
  
  **--cbuild examples**. (versions later than 1.18.5, found in Stretch 9 + )  
   ./duebuild --cbuild --build= takes as , separated list:  
     all    - architecture independent (type 'all')  
     any    - architecture dependent (amd64, armel, etc)  
     source - source only.  
     binary - architecture dependent, independent, and no source.  
     full   - build everything = source,any,all.  
    So to build all binaries, no source:  
    ./duebuild `--cbuild  `--build=any,all  
  
  Build source, arch specific and type 'all' (default -uc -us)  
   `./duebuild --cbuild`  

  Insert a string into the version  
   `./duebuild --cbuild --dev-version ~1234`  

  Set DEB_BUILD_OPTIONS values:  
   `./duebuild --cbuild --deb-build-option debug --deb-build-option nostrip`  
  
  Store build products in a repository above the build directory for future builds  
  (i.e. building things that need other things built to build...)  
   `./duebuild --cbuild --use-local-repo myLocalRepo`  
   Or specify that repository with an absolute (container relative) path:  
   `./duebuild --cbuild --use-local-repo /path/to/myLocalRepo`   

  Do environmental setup and run dpkg-buildpackage -uc -us -j8  
   `./duebuild --build-command dpkg-buildpackage -uc -us -j8`  

  Examples from DUE:  
   Build package with 'nostrip' and 'debug' options,   
   unsigned source, unsinged changes file, build binary, 5 jobs,  
   and reference local package repository 'myLocalRepo'  
     due `--build `--jobs 5 `--deb-build-option nostrip   
     --deb-build-option debug `--use-local-repo myLocalRepo   
     --cbuild -us -uc -b`  
     
