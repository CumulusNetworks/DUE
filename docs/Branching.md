# A brief explanation of branches.
Copyright 2022,2023 Nvidia Corporation.  All rights reserved.

# master
 This is the upstream - changes are introduced here, and it has some ability to install DUE using the Makefile.
 It has no Linux distribution specific packaging files.  
 It can create the 'upstream tarball' used in distribution specific packaging (.deb,.rpm) via `make orig.tar`  


# debian/master
  This is the top level for Debian packaging, and it does have Debian specific packaging files.
  It is not release specific, but can be used to build DUE as an installable Debian package.
  When an upstream release is generated, the files in this branch will be synced to master so that a clean snapshot  
  of what was upstreamed is available.
  See [GettingStarted.md](GettingStarted.md) for directions for generating a tarfile from the `master` branch, and building
  on `debian/master`

  This holds the debian/changelog, and gets updated via 'git merge master'

# debian/test
  This is a prototyping branch to debug any packaging issues so that updates to debian/master are as clear as possible.

# rpm/master
  This is the top level for RPM packaging, and contains RPM specific packaging files.  
  As this is not currently upstreamed, it does not contain a snapshot of the files, and just packages using the DUE code provided by the `orig.tar` file.
  
  