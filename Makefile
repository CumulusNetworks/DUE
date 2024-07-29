#!/usr/bin/make -f

# Copyright 2021-2024 Nvidia Corporation.  All rights reserved.
# Copyright 2019,2020 Cumulus Networks, Inc.  All rights reserved.
#
#  SPDX-License-Identifier:     MIT

# Set the version in libdue as the source of truth
DUE_VERSION := $(shell /bin/sh -c "grep -o 'DUE_VERSION=\".*\"' ./libdue | sed -e 's/DUE_VERSION=//g' | tr -d \\\" " )

# The source tarball
DUE_ORIG_TAR=due_$(DUE_VERSION).orig.tar.gz

# Branch to use when building a Debian package.
DEBIAN_PACKAGE_BRANCH ?= debian/master

# Holds the due.spec for building RPMs
RPM_PACKAGE_BRANCH ?= rpm/master

# As package builds will check out master/debian or master/rpm branches to get the
# operating system specifics of the packaging, it is important to keep track of
# the current branch.
CURRENT_GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

# Uncomment the following to enable more makefile output
#export DH_VERBOSE = 1

# Configuration for make install, with some caveats:
#  Debian OSs lean towards docker.io
#  Red Hat OSs lean twoards Podman
#  Ubuntu running in Windows Subsytstem For Linux will use Podman, as the Docker daemon...doesn't
#   ...and there may be Debian/Ubuntu systems using Podman
# If Docker or Podman is already installed, use that as the DOCKER_TO_INSTALL so
#  that apt/dnf/zypper, etc will leave it unchanged.

# Is docker installed? Send any basename errors to /dev/null.
DOCKER_PRESENT := $(shell basename $$(which docker) 2>/dev/null )
ifeq ($(DOCKER_PRESENT),docker)
	DOCKER_TO_INSTALL := docker.io
endif
# If Podman is installed, don't try to bring Docker to the party.
PODMAN_PRESENT := $(shell basename $$(which podman) 2>/dev/null  )
ifeq ($(PODMAN_PRESENT),podman)
	DOCKER_TO_INSTALL := podman
endif

# /etc/os-release can be a mess. Assume that for a given image, it won't mention
# other OSs, and search for only supported OSs. USe := so it can be overridden from
# the command line.

# Valid values: debian, fedora, suse
IS_DEBIAN :=	$(shell grep -qi 'debian' /etc/os-release && echo 'debian' )
IS_FEDORA :=	$(shell grep -qi 'fedora' /etc/os-release && echo 'fedora' )
IS_SUSE   :=	$(shell grep -qi 'suse'   /etc/os-release && echo 'suse' )


# Check for directories that would only be present if a .deb or rpm is being built.
# In this case the Makefile should do nothng if invoked, since it should not
# be part of the packaging in the first place.
# Developers can easily override this by changing the name of the packaging file
# to look for.
ifneq (,$(wildcard ./debian/control))
	OS_PACKAGING_MESSAGE := debian/control file found, so Makefile is doing nothing.
endif

# If this fails to be set to something valid, give the user a hint as to why.
PACKAGE_MANAGER = failed-to-determine-package-manager

#
# If Docker/Podman is not already installed, add one based on host OS.
#
# Red Hat like OSs lean towards Podman
# Default to yum as it may be more universal than the new 'dnf'
ifeq ($(IS_FEDORA),fedora)
	DOCKER_TO_INSTALL ?= podman
	PACKAGE_MANAGER := yum
	HOST_OS := fedora
endif

ifeq ($(IS_DEBIAN),debian)
	PACKAGE_MANAGER := apt
	ADDITIONAL_PACKAGES := bsdutils
	DOCKER_TO_INSTALL ?= docker.io
	HOST_OS := debian
endif

ifeq ($(IS_SUSE),suse)
	DOCKER_TO_INSTALL ?= docker.io
	PACKAGE_MANAGER := zypper
	HOST_OS := suse
endif

# If Docker is, or is going to be installed, remind the user about group membership.
ifeq ($(DOCKER_TO_INSTALL),docker.io)
	DOCKER_INSTALL_MESSAGE ?= "Finally, add yourself to the user group with: sudo /usr/sbin/usermod -a -G docker $(shell whoami)"
endif

#
# The merge directory holds intermediate stages in setting
# up an image. It is not needed to build DUE into a .deb,
# but it will interfere with Git seeing a clean directory.
#
MERGE_DIR = due-build-merge

# Path to install of Pandoc.
PANDOC_PRESENT = /usr/bin/pandoc

# Detect if in Debian build area
DEBIAN_BUILD_BRANCH = ./debian

# Manual page is generated from manpage-due-1.md via Pandoc
MAN_PAGE = docs/due.1
MAN_PAGE_SOURCE = docs/manpage-due-1.md
MASTER_CHANGE_LOG = ChangeLog

# Common packages required to run DUE
# Rsync is used in merging template directories
# jq and curl get used to browse docker registries
# pandoc gets used to turn markdown into man pages, and is optional
DUE_DEPENDENCIES = git rsync jq curl

GIT_STASH_MESSAGE = "Preserving master branch"
#
# Set V=1 to echo out Makefile commands
#
# Unless set, V is 0
V ?= 0
# Q is set to '@' to NOT echo Makefile output
Q = @
ifneq ($V,0)
# If V is not 0, then Q is not '@' and the command is echoed.
	Q = 
endif

# If no make target specified, print help
.DEFAULT_GOAL := help

# If files to package for a particular OS are present, let those rules/spec files
# handle the make.
ifneq (,$(OS_PACKAGING_MESSAGE))
help:

	@echo ""
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# $(OS_PACKAGING_MESSAGE)"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""

else
#
# Store phony build targets in a variable so they can be
# printed as part of help.
#
PHONY = help docs depends install uninstall orig.tar debian-package rpm-package test no-make-default copyright-check clean rebase-upstream run-lintian 

# ...and use them as real .PHONY targets
.PHONY: $(PHONY)

# If doing a Debian package build  dh_auto_build will execute the first target
#  in a found Makefile. It is already executing debian/rules, so just print a
#  a message and continue on.
no-make-default:
	$(Q) echo "No default Makefile actions. Try 'make help'."

# Print our targets
help:
	$(Q) echo ""
	$(Q) echo "######################################################################"
	$(Q) echo "#                                                                    #"
	$(Q) echo "#  Dedicated User Environment make help.                             #"
	$(Q) echo "#                                                                    #"
	$(Q) echo "######################################################################"
	$(Q) echo ""
	$(Q) echo " Common targets"
	$(Q) echo "----------------"
	$(Q) echo " install         - Install DUE and dependencies."
	$(Q) echo " depends         - Install DUE's run time dependencies."
	$(Q) echo " clean           - Delete all generated files."
	$(Q) echo "  V=1            - Enable Makefile debug. Use with other targets. Ex: make V=1 install"
	$(Q) echo ""
	$(Q) echo " orig.tar        - Create tarball for packaging."
	$(Q) echo " debian-package  - Build DUE as .deb package."
	$(Q) echo "                     Requires a package-debian image (Ubuntu, Debian,etc) built from ./due --create."
	$(Q) echo " rpm-package     - Build DUE as an .rpm package."
	$(Q) echo "                     Requires a package-rpm image (Fedora, SUSE, etc) build from  ./due --create."
	$(Q) echo ""
	$(Q) echo " Developer targets"
	$(Q) echo "-------------------"
	$(Q) echo ""
	$(Q) echo " debian-test     - Build off debian-test branch with 'make debian-package DEBIAN_PACKAGE_BRANCH=debian-test'"
	$(Q) echo " copyright-check - Print files without a copyright header."
	$(Q) echo " run-lintian     - Run lintian on ../due_$(DUE_VERSION)*all.deb"
	$(Q) echo " rebase-upstream - Rebase a remote branch to the latest DUE"
	$(Q) echo " docs            - Rebuild man pages and other documentation. Can be run in a container."

	$(Q) echo ""

	$(Q) echo ""
	$(Q) echo " Makefile targets:"
	$(Q) for I in $(sort $(PHONY)); do echo "    $$I"; done
	$(Q) echo ""

docs: $(MAN_PAGE)
# Docs will not automatically rebuild.
# Run:
#      /usr/bin/make -f ./debian/rules docs
# To update documentation.
# If Pandoc is installed generate the man page from man.md
# Otherwise, use the last checked in version of it.
#  Odds are any users building this will be looking to build the
#  installer and not make changes to the man pages.
# Pandoc can pull in 50-150 MB of additional files, which may be
#  a bit of an ask.
ifneq ($(wildcard $(PANDOC_PRESENT)),)
	@echo ""
	@echo "#######################################################################"
	@echo "#                                                                     #"	
	@echo "# Pandoc detected: updating documentation "
	@echo "# Removing existing $(MAN_PAGE) "
	$(Q)  rm $(MAN_PAGE)

	@echo "# Setting version to [ $(DUE_VERSION) ] in docs/manpage-due-1.md "
	$(Q)  sed -i 's/DUE(1) Version.*|/DUE(1) Version $(DUE_VERSION) |/' $(MAN_PAGE_SOURCE)

	@echo "# Setting version to [ $(DUE_VERSION) ] in ChangeLog "
	$(Q)  sed -i '0,/due (.*-1) / s/due (.*-1) /due ($(DUE_VERSION)-1) /' $(MASTER_CHANGE_LOG)

	@echo "# Generating new man page from docs/manpage-due-1.md "
	$(Q)  pandoc --standalone --to man docs/manpage-due-1.md -o $(MAN_PAGE)
	@echo ""
	$(Q)  /bin/ls -lrt ./docs

	@echo "#                                                                    #"	
	@echo "#######################################################################"
	@echo ""
else
	@echo ""
	@echo "#######################################################################"
	@echo "# Pandoc is not installed. NOT regenerating due.1 man page            #"
	@echo "#                                                                     #"
	@echo "# If you want to update the man pages:                                #"
	@echo "#    apt-get install pandoc                                           #"
	@echo "# ...and retry this make -f debian/control docs                       #"
	@echo "#                                                                     #"
	@echo "#######################################################################"
	@echo ""
endif

clean:
	@echo ""
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Removing the following, if they exist.                             #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
ifneq ($(wildcard /usr/bin/dpkg),)
	@echo "# Cleaning for Debian builds."
	rm -f   ../*.build                    
	rm -f   ../due_$(DUE_VERISON)* 
	rm -f   ../$(DUE_ORIG_TAR)   
	rm -rf   ./$(MERGE_DIR)
endif
ifneq ($(wildcard /usr/bin/rpm),)
	@echo "# Cleaning for RPM builds."
	rm -f   $(HOME)/rpmbuild/RPMS/noarch/due-*noarch.rpm
	rm -f   $(HOME)/rpmbuild/SOURCES/due_*orig.tar.gz
	rm -f   $(HOME)/rpmbuild/SPECS/due.spec
	rm -rf  $(HOME)/rpmbuild/BUILD/due-*
endif
	@echo ""
	@echo "Done making clean."
	@echo ""

rebase-upstream:
	@echo ""
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Rebasing master branch to latest upstream DUE                      #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	@echo " Stashing changes "
	git stash
	@echo " Checking out master branch"
	git checkout master
	@echo " Running:    git remote add upstream https://github.com/CumulusNetworks/DUE.git"
	git remote add upstream https://github.com/CumulusNetworks/DUE.git
	@echo " Fetching upstream"
	git fetch upstream
	@echo " Rebasing off upstream/master"
	git rebase upstream/master
	@echo " Any changes were stashed before rebase."
	@echo " If automatic rebase failed, resolving conflicts is left as an exercise for the developer."
	@echo ""
	@echo "Done"


run-lintian:
	@echo ""
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Checking recently built ../due_$(DUE_VERSION)_all*deb                       #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	$(Q)  - lintian ../due_$(DUE_VERSION)*all.deb
	@echo ""
	@echo " A return code of 2 is accptable IF the due.lintian-overrides produced no errors."
	@echo ""

depends:
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# DUE requires the following packages:                               #"
	@echo "#                                                                    #"
	@echo "#   $(DUE_DEPENDENCIES) $(ADDITIONAL_PACKAGES)$(DOCKER_TO_INSTALL)                  "
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	@echo "Detected [ $(HOST_OS) ] Linux. Installing dependencies."
	@echo "" 
	$(Q) sudo $(PACKAGE_MANAGER) install $(DUE_DEPENDENCIES) $(DOCKER_TO_INSTALL) 
	@echo "" 
	@echo "Done installing dependencies."
	@echo "" 

install: depends
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Installing DUE by copying the following files:                     #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""

	sudo cp         ./due              /usr/bin
	sudo cp         ./libdue           /usr/lib
	sudo cp         ./docs/due.1       /usr/share/man/man1

	sudo mkdir -p  /etc/due
	sudo cp         ./etc/due/due.conf /etc/due

	sudo mkdir -p  /usr/share/due
	sudo cp -r      ./templates        /usr/share/due
	sudo cp -r      ./image-patches    /usr/share/due
	sudo cp -r      ./README.md        /usr/share/due

#Podman doesn't require a group membership, but Docker does.
	@echo "" 
	@ echo $(DOCKER_INSTALL_MESSAGE)
	@echo "" 
	@echo "Done installing DUE."
	@echo "" 

uninstall:
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Uninstalling DUE by deleting the following files:                  #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	sudo rm        /usr/bin/due
	sudo rm        /usr/lib/libdue
	sudo rm        /usr/share/man/man1/due.1

	sudo rm -rf    /etc/due
	sudo rm -rf    /usr/share/due

# Create 'upstream tarball' for use in packaging.
# Existing tar files have to be manually deleted. A release build requires using the 
# same original tar file for .deb and .rpm packaging, so it should not be recreated
# between the two builds.
orig.tar:
		@echo "######################################################################"
		@echo "#                                                                    #"
		@echo "# Building DUE source tar file: $(DUE_ORIG_TAR)                #"
		@echo "#                                                                    #"
		@echo "######################################################################"
		@echo ""

# Reminder. ifneq has to be at the same indentation as the target.
# Otherwise you get : /bin/sh: 1: Syntax error: word unexpected (expecting ")")
ifneq ("$(wildcard ../$(DUE_ORIG_TAR))","")
		@echo "$(DUE_ORIG_TAR) exists."
		$(Q) ls -lrt ../*.gz
		@echo ""
		@echo "Skipping tar file creation."
		@echo ""
else
		$(Q) git archive --format=tar.gz --prefix=due_$(DUE_VERSION)/  -o ../$(DUE_ORIG_TAR)  master
		@echo "Produced tar file [ $(DUE_ORIG_TAR) ] in [ $(shell dirname $$(pwd)) ] from Git branch [ $(CURRENT_GIT_BRANCH) ]"
		$(Q) ls -lrt ../*.gz
		@echo ""
endif
#	$(Q) touch $@


debian-test:
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Building the debian-test branch.                                   #"
	@echo "# Make sure 'git-rebase master' has been run from it.                #"
	@echo "#                                                                    #"
	@echo "######################################################################"

	make debian-package DEBIAN_PACKAGE_BRANCH=debian-test

# Create upstream tarball and build DUE .deb file from DEBIAN_PACKAGE_BRANCH
#  To build the debian-test branch:
#    make debian-package DEBIAN_PACKAGE_BRANCH=debian-test
debian-package: orig.tar
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Building DUE Debian installer package.                             #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	@echo "# Stashing any local Git changes."
	$(Q) git stash 
	@echo "# Checking out $(DEBIAN_PACKAGE_BRANCH) branch."
	$(Q) git checkout $(DEBIAN_PACKAGE_BRANCH)
	@echo ""
# Keep the option to extract master tarball in to a directory of
# strictly Debian files. This would be used only during testing
# development packaging builds, since the debian/master branch
# contains snapshots of the versions of DUE files that have been
# upstreamed, and will only be updated during upstreaming efforts.
#	@echo "# Extracting tarball."
	$(Q) tar -xvf ../$(DUE_ORIG_TAR) --strip-components=1
ifneq ($(wildcard ../due_$(DUE_VERSION)*_all.deb),)
	@echo " Previous ../due_$(DUE_VERSION)*_all.deb exists. Removing"
	rm ../due_$(DUE_VERSION)*_all.deb
	@echo ""
endif
	@echo ""
	@echo "# Select a Debian package build container to build in:"
# The true here forces the Makefile to keep running so the user isn't left with
# a build that has changes on a different branch.
# Remove the ; true to debug build behavior.
	$(Q) ./due --duebuild --build-command dpkg-buildpackage -us -uc ; true
	@echo ""
	@echo "# Deleting files extracted from tar archive with: [ git clean -xdf ]"
	$(Q) git clean -xdf
	@echo ""
	@echo "# Resetting $(DEBIAN_PACKAGE_BRANCH) branch with: [ git reset --hard ]"
	$(Q) git reset --hard
	@echo ""
	@echo "# Returning to $(CURRENT_GIT_BRANCH) with: [ git checkout $(CURRENT_GIT_BRANCH) ]"
	$(Q) git checkout $(CURRENT_GIT_BRANCH)
	@echo ""
	@echo "# Applying any local master branch stash changes with: [ git stash pop ]"
#Use - to ignore errors if nothing pops, and ||: to avoid warnings if nothing to pop.
	- $(Q) git stash pop ||:
	@if [ -e ../due_$(DUE_VERSION)*_all.deb ]; then \
		echo "#" ;\
		echo "# New .deb build products are in $(shell dirname $$(pwd)):" ;\
		echo "# --------------------------------" ;\
		ls -lrt ../due_* ;\
	else \
		pwd ;\
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" ;\
		echo "!                                                                    !" ;\
		echo "! Build FAILED. To examine the failure on the $(DEBIAN_PACKAGE_BRANCH) branch   ! " ;\
		echo "!  remove the '; true' from the Makefile's build line.               !" ;\
		echo "!                                                                    !" ;\
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" ;\
		echo "" ;\
	fi
	@echo "" 
	@echo "# Done."
	@echo ""



# Create upstream tarball and build DUE .rpm file from RPM_PACKAGE_BRANCH
# changing branches as needed.
rpm-package: orig.tar
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Building DUE RPM installer package.                                #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	@echo "# Stashing any local Git changes."
#use 'git stash drop' if stashed files pile up in the debug of this again.
	$(Q)  git stash 
	@echo "# Checking out $(RPM_PACKAGE_BRANCH) branch." 
	$(Q)  git checkout $(RPM_PACKAGE_BRANCH) 
	@echo ""
	@echo "# Creating rpmbuild directory under $(HOME)"
	$(Q) mkdir -p $(HOME)/rpmbuild/BUILD
	$(Q) mkdir -p $(HOME)/rpmbuild/RPMS
	$(Q) mkdir -p $(HOME)/rpmbuild/SOURCES
	$(Q) mkdir -p $(HOME)/rpmbuild/SPECS
	$(Q) mkdir -p $(HOME)/rpmbuild/SRPMS
	@echo "# Copying DUE tar file to $(HOME)/rpmbuild/SOURCES"
	$(Q) cp ../$(DUE_ORIG_TAR) $(HOME)/rpmbuild/SOURCES
	@echo "# Copying rpm-package/due.spec file to $(HOME)/rpmbuild/SPECS"
	$(Q) cp rpm-package/due.spec $(HOME)/rpmbuild/SPECS/
ifneq ($(wildcard $(HOME)/rpmbuild/RPMS/noarch/due-$(DUE_VERSION)*.noarch.rpm),)
	@echo " Previous $(HOME)/rpmbuild/RPMS/noarch/due-$(DUE_VERSION)*.noarch.rpm exists. Removing"
	rm $(HOME)/rpmbuild/RPMS/noarch/due-$(DUE_VERSION)*.noarch.rpm
	@echo ""
endif
	@echo ""
	@echo "# Select an RPM package build container (Fedora/RHEL/SUSE, etc) to build in:"
	$(Q) ./due --run --command rpmbuild --target noarch --bb $(HOME)/rpmbuild/SPECS/due.spec ; true
	@echo ""
	@echo "# Build invoked with: ./due --run --command rpmbuild --target noarch --bb $(HOME)/rpmbuild/SPECS/due.spec ; true"
	@echo ""
	@echo "# Deleting generated and copied in files with: [ git clean -xdf ]"
	$(Q) git clean -xdf
	@echo ""
	@echo "# Resetting $(RPM_PACKAGE_BRANCH) branch with: [ git reset --hard ]"
	$(Q) git reset --hard
	@echo ""
	@echo "# Checking out $(CURRENT_GIT_BRANCH) branch with: [ git checkout $(CURRENT_GIT_BRANCH) ]"
	$(Q) git checkout $(CURRENT_GIT_BRANCH)
	@echo ""
	@echo "# Applying any local $(CURRENT_GIT_BRANCH) branch stash changes with: [ git stash pop ]"
#Use - to ignore errors if nothing pops, and ||: to avoid warnings if nothing to pop.
	- $(Q) git stash pop ||:
	@echo ""
	@if [ -e $(HOME)/rpmbuild/RPMS/noarch/due-$(DUE_VERSION)*.noarch.rpm ]; then \
		echo "#" ;\
		echo "# RPM build products are in $(HOME)/rpmbuild/RPMS/noarch/" ;\
		echo "# --------------------------------" ;\
		ls -lrt $(HOME)/rpmbuild/RPMS/noarch/ ;\
	else\
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" ;\
		echo "!                                                                    !" ;\
		echo "! Build FAILED. To examine the failure on the $(RPM_PACKAGE_BRANCH) branch      !" ;\
		echo "!  remove the '; true' from the Makefile's build line.               !" ;\
		echo "!                                                                    !" ;\
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" ;\
		echo "" ;\
	fi
	@echo ""
	@echo "# Done."
	@echo ""


debian: orig.tar
	@ echo "Building DUE Debian installer package."
	@ git checkout $(DEBIAN_PACKAGE_BRANCH)
	@ ./due --build

copyright-check:
	@echo ""
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# The following files do NOT have a copyright header                 #"
	@echo "# Ex: Copyright 2021,2022 Nvidia Corporation.  All rights reserved.  #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""

#grep -L to find files that do not match for search term. Ignore .git directory
	@ find ./ -type f  -exec grep -Li 'Copyright' {} \+ | grep -v '.git'
	@echo ""
	@echo "Done."
	@echo ""

test:
# A target for makefile debug.
	@echo "Due version       $(DUE_VERSION)"
	@echo "Docker to install $(DOCKER_TO_INSTALL)"
	@echo "Package manager   $(PACKAGE_MANAGER)"
	@echo "Host OS           $(HOST_OS)"
	@echo "Deb pkg branch    $(DEBIAN_PACKAGE_BRANCH)"
	@if [ -e ../due_$(DUE_VERSION)*_all.deb ]; then \
	echo "GOT file" ; \
	else \
	echo "No file" ;\
	fi

# Matches OS_PACKAGING_MESSAGE
endif
