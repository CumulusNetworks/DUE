# A brief explanation of branches, through change propagation.

# master
 This is the upstream - changes are introduced here, and it has some ability to install DUE using the Makefile.
 It has no Debian specific packaging files.  
 It also creates the 'upstream tarball' via `make orig.tar`  


# debian/master
  This is the top level for Debian packaging, and it does have Debian specific packaging files.
  It is not release specific, but can be used to build DUE as an installable Debaian package.
  It's debian/source/format is 3.0 (git)

  This holds the debian/changelog, and gets updated vi 'git merge master'

# debian/buster
  This is used to geneerate buster release-specific source packages, and it's debian/changelog file
  does have release specific references.  Given the original tar file generated from Master,
  a `dpkg-buildpackage --unsigned-source` will create all the files that are necessary for a
  Debian build from source.

  It's debian/source/format is 3.0 (quilt)

  This holds the debian/changelog to be used for Buster and gets updated via
  'git merge debian-upstream'


  