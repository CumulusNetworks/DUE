rpm/master branch
-----------------

This branch is used for packaging DUE as an RPM.
It contains a due.spec file that is used to package
an 'upstream tarball' (makefile target: orig.tar)
as an RPM installer.  

It expects that the master makefile will:  
 

  * Stash any changes on the master branch.  
  * Check out this branch.  
  * Create a $(HOME)/rpmbuild tree.  
  * Copy due_*orig.tar.gz to $(HOME)/rpmbuild/SOURCES.  
  * Copy rpm-package/due.spec to $(HOME)/rpmbuild/SPECS.  
  * Have the user choose a Docker image capable of building RPMS ( a Red Hat or SUSE image )
 so that `./due --run --command rpmbuild --target noarch --bb $(HOME)/rpmbuild/SPECS/due.spec` can be run.  
  * Runs a `git clean -xdf` to avoid any complaints when checking out the master branch again.  
  * Checks out the master branch.  
 Runs `git stash pop` to return the master branch to its original state.  
  
**NOTE** that this is the intial commit of the `due.spec` file, and it probably requires some fine tuning, although it does seem to work.  




