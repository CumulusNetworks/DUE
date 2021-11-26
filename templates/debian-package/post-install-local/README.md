post_install_local/  
--------------------

The `post-install-config.sh.template` 
will use the contents of this directory to perform any additional operations at the end of container configuration.   
By default, any `*.deb` files in this directory will be installed in
the container, and an:  
 `apt-get install --assume-yes --fix-broken`  
will be run to resolve any new dependencies, using the container's
Apt configuration.
