# Free Range Routing

This is a first pass at a configuration to build Debian packages
for Free range routing, so expect some rough edges.

Notes:
This configuraion has the key for the FRR repository in 
  filesystem/etc/apt/trusted.gpg.d/keys.asc
  Should the key change, this will need to be updated.

This steals the dpkg-plus script from the debian-packge template.
Now I've got the same thing in two places, which is always a bad idea.
This will need to get addressed at some point.

Suggested configuration:
	Use a debian 10 container (though ubuntu:18.04 works nicely as well)
	name it frrd10
	tag it as frr-debian10
	set the prompt in container to be FRRD10 so the context is (more) obvious
	merge in the files from ./templates/frr when creating the configuration direcotry

## Image creation example.
<br>
Create default frr build environment with: ./due --create --from debian:10 --description "Free Range Routing Debian 10" --name frrd10 --prompt FRRD10 --tag frr-debian10 --use-template frr

## Reference link
 http://docs.frrouting.org/projects/dev-guide/en/latest/building-frr-for-ubuntu1804.html#installing-dependencies

There is some preconfiguration to be done, so at the moment this gets built inside
the container, rather than just invoking due and the container on a directory to build.

I'll look at a pre build configuration script option to 'just handle' this.

--- start bash script ----
#!/bin/bash
echo "Executing FRR prebuild script"
pwd
echo "Running bootstrap.sh"
./bootstrap.sh
echo "Running configure"

./configure \
    --prefix=/usr \
    --includedir=\${prefix}/include \
    --enable-exampledir=\${prefix}/share/doc/frr/examples \
    --bindir=\${prefix}/bin \
    --sbindir=\${prefix}/lib/frr \
    --libdir=\${prefix}/lib/frr \
    --libexecdir=\${prefix}/lib/frr \
    --localstatedir=/var/run/frr \
    --sysconfdir=/etc/frr \
    --with-moduledir=\${prefix}/lib/frr/modules \
    --with-libyang-pluginsdir=\${prefix}/lib/frr/libyang_plugins \
    --enable-configfile-mask=0640 \
    --enable-logfile-mask=0640 \
    --enable-snmp=agentx \
    --enable-multipath=64 \
    --enable-user=frr \
    --enable-group=frr \
    --enable-vty-group=frrvty \
    --with-pkg-git-version \
    --with-pkg-extra-version=-MyOwnFRRVersion \
    --enable-systemd=yes

--- end bash script ----
 I'd suggest running dpkg-plus --build to resolve any lingering build dependencies.
 However, all the ./debian/* files should be here at this point, so dpkg-buildpackage 
 should work to create installation debs

 Or you can:
 make
 sudo make install
