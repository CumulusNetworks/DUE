Name:           due
Version:        4.0.0
Release:        1%{?dist}
Summary:        Dedicated User Environment: manage build environments in Docker containers.
License:        MIT
URL:            https://github.com/CumulusNetworks/DUE
Source0:        https://github.com/CumulusNetworks/DUE/archive/refs/tags/due_%{version}.orig.tar.gz
BuildRequires:  git
BuildArch:      noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       (docker.io or docker-ce or podman)
Requires:       git
Requires:       rsync
Requires:       jq
Requires:       curl

%description
Dedicated User Environment: manage build environments in Docker containers
 DUE uses templates to generate target specific build images based on any
 version or architecture of any Debian release, and provides a launcher
 application to reduce complexity and let the developer 'just build it',
 whatever 'it' may happen to be.


%prep
# Adjust the due_x.y.z.orig.tar.gz file to be due-x.y.z for RPM build
%setup -c  -n %{name}-%{version}
# the -n doesn't seem to work, so create a nested directory, and move
# everything up out of it
mv %{_builddir}/%{name}-%{version}/%{name}_%{version}/* %{_builddir}/%{name}-%{version}
rm -rf %{_builddir}/%{name}-%{version}/%{name}_%{version}

# %%autosetup

#Disable build
# %%build
#Disable configure
# %%configure
#Disable make_build
# %%make_build

# Build with
# rpmbuild --target noarch -bb ~/rpmbuild/SPECS/due.spec 
%install
rm -rf $RPM_BUILD_ROOT
# bin
mkdir -p %{buildroot}/usr/bin/
cp %{_builddir}/%{name}-%{version}/due %{buildroot}/usr/bin
# Lib
mkdir -p %{buildroot}/usr/lib
cp %{_builddir}/%{name}-%{version}/libdue %{buildroot}/usr/lib/
# Licenses
mkdir -p %{buildroot}/usr/share/licenses/due
cp %{_builddir}/%{name}-%{version}/LICENSE.txt %{buildroot}/usr/share/licenses/due/LICENSE.txt
# Templates
mkdir -p %{buildroot}/usr/share/due
cp -r %{_builddir}/%{name}-%{version}/templates %{buildroot}/usr/share/due/templates
# Docs
mkdir -p %{buildroot}/usr/share/docs/due
cp -r %{_builddir}/%{name}-%{version}/docs/* %{buildroot}/usr/share/docs/due/
# Man pages
mkdir -p %{buildroot}/usr/share/man/man1/due.1
mv %{buildroot}/usr/share/docs/due/due.1  %{buildroot}/usr/share/man/man1/due.1
# etc conf
mkdir -p %{buildroot}/etc/due/
cp %{_builddir}/%{name}-%{version}/etc/due/due.conf %{buildroot}/etc/due/due.conf



#tar -xvf %{_sourcedir}/due_4.0.0.orig.tar.gz --strip-components=1 -C %{buildroot}
# %%make_install

%files
/etc/due/due.conf
/usr/bin/due
/usr/lib/libdue
/usr/share/due/templates/README.md
/usr/share/due/templates/common-templates/Dockerfile.config
/usr/share/due/templates/common-templates/Dockerfile.template
/usr/share/due/templates/common-templates/README.md
/usr/share/due/templates/common-templates/duebuild-readme.md
/usr/share/due/templates/common-templates/filesystem/etc/DockerLoginMessage.template
/usr/share/due/templates/common-templates/filesystem/etc/due-bashrc.template
/usr/share/due/templates/common-templates/filesystem/usr/local/bin/container-create-user.sh
/usr/share/due/templates/common-templates/filesystem/usr/local/bin/duebuild
/usr/share/due/templates/common-templates/install-config-common-lib.template
/usr/share/due/templates/common-templates/post-install-config.sh.template
/usr/share/due/templates/common-templates/pre-install-config.sh.template
/usr/share/due/templates/debian-package/Dockerfile.config
/usr/share/due/templates/debian-package/README.md
/usr/share/due/templates/debian-package/duebuild-readme.md
/usr/share/due/templates/debian-package/filesystem/usr/local/bin/due-manage-local-repo.sh
/usr/share/due/templates/debian-package/filesystem/usr/local/bin/duebuild
/usr/share/due/templates/debian-package/post-install-config.sh.template
/usr/share/due/templates/debian-package/post-install-local/README.md
/usr/share/due/templates/example/Dockerfile.config
/usr/share/due/templates/example/README.md
/usr/share/due/templates/example/post-install-config.sh.template
/usr/share/due/templates/frr/Dockerfile.config
/usr/share/due/templates/frr/README.md
/usr/share/due/templates/frr/filesystem/etc/DockerLoginMessage
/usr/share/due/templates/frr/filesystem/etc/apt/trusted.gpg.d/keys.asc
/usr/share/due/templates/frr/filesystem/etc/due-bashrc
/usr/share/due/templates/frr/filesystem/usr/local/bin/duebuild
/usr/share/due/templates/frr/post-install-config.sh.template
/usr/share/due/templates/onie/Dockerfile.config
/usr/share/due/templates/onie/README.md
/usr/share/due/templates/onie/filesystem/etc/apt/sources.list.d/stretch-backports.list
/usr/share/due/templates/onie/filesystem/etc/due-bashrc.template
/usr/share/due/templates/onie/filesystem/usr/local/bin/duebuild
/usr/share/due/templates/onie/post-install-config.sh.template
/usr/share/due/templates/redhat/filesystem/usr/local/bin/duebuild
/usr/share/due/templates/redhat/sub-type/fedora-package/Dockerfile.config
/usr/share/due/templates/redhat/sub-type/fedora-package/README.md
/usr/share/due/templates/redhat/sub-type/fedora-package/post-install-config.sh.template
/usr/share/due/templates/redhat/sub-type/rhel-package/Dockerfile.config
/usr/share/due/templates/redhat/sub-type/rhel-package/README.md
/usr/share/due/templates/redhat/sub-type/rhel-package/post-install-config.sh.template
/usr/share/due/templates/suse/filesystem/usr/local/bin/duebuild
/usr/share/due/templates/suse/post-install-config.sh.template
/usr/share/due/templates/suse/sub-type/opensuse-package/Dockerfile.config
/usr/share/due/templates/suse/sub-type/opensuse-package/README.md
/usr/share/due/templates/suse/sub-type/sles-package/Dockerfile.config
/usr/share/due/templates/suse/sub-type/sles-package/README.md
/usr/share/man/man1/due.1/due.1.gz


%license /usr/share/licenses/due/LICENSE.txt
%doc  /usr/share/docs/due

%changelog
* Thu Dec 29 2022 Alex Doyle <alexddoyle@gmail.com>
- First version being packaged
