#!/usr/bin/make -f

# Set the version in libdue as the source of truth
DUE_VERSION := $(shell /bin/sh -c "grep -o 'DUE_VERSION=\".*\"' ./libdue | sed -e 's/DUE_VERSION=//g' | tr -d \\\" " )

# The source tarball
DUE_ORIG_TAR=due_$(DUE_VERSION).orig.tar.gz

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
PODMAN_PRESENT := $(shell basename $$(which podman) )
ifeq ($(PODMAN_PRESENT),podman)
	DOCKER_TO_INSTALL := podman
endif

# Use ID_LIKE from /etc/os-release to make installation decisions.
# Possible values: debian, fedora, suse
HOST_OS :=	$(shell grep 'ID_LIKE=' /etc/os-release | sed -e 's/^.*=//')

#
# If Docker/Podman is not already installed, add one based on host OS.
#
# Red Hat like OSs lean towards Podman
ifeq ($(HOST_OS),fedora)
	DOCKER_TO_INSTALL ?= podman
else
# Debian, Ubuntu, SUSE
	DOCKER_TO_INSTALL ?= docker.io
endif

# If Docker is, or is going to be installed, remind the user about group membership.
ifeq ($(DOCKER_TO_INSTALL),docker.io)
	DOCKER_INSTALL_MESSAGE ?= "Finally, add yourself to the user group with: sudo /usr/sbin/usermod -a -G docker $(shell whoami)"
endif

#Package manager to use
ifeq ($(HOST_OS),fedora)
	PACKAGE_MANAGER := yum
endif
ifeq ($(HOST_OS),debian)
	PACKAGE_MANAGER := apt
	ADDITIONAL_PACKAGES := bsdutils
endif
ifeq ($(HOST_OS),suse)
	PACKAGE_MANAGER := zypper
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

#
# Store phony build targets in a variable so they can be
# printed as part of help.
#
PHONY = help docs depends install uninstall orig.tar debian-package test no-make-default

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
	$(Q) echo "Dedicated User Environment make help."
	$(Q) echo "----------------------------------------"
	$(Q) echo " debian-package  - build DUE as .deb file."
	$(Q) echo "                     Requires debian-package image from ./due --create."
	$(Q) echo " depends         - install DUE's run time dependencies."
	$(Q) echo " install         - install DUE and dependencies."
	$(Q) echo " orig.tar        - create tarball for packaging."
	$(Q) echo ""
	$(Q) echo " Make with 'make V=1' for makefile debug."
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

depends:
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# DUE requires the following packages:                               #"
	@echo "#                                                                    #"
	@echo "#   $(DUE_DEPENDENCIES) $(ADDITIONAL_PACKAGES) $(DOCKER_TO_INSTALL)                  "
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	@echo "Installing dependencies for ID_LIKE=$(HOST_OS) Linux" 
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

	sudo cp        ./due               /usr/bin
	sudo cp        ./libdue            /usr/lib
	sudo cp        ./docs/due.1        /usr/share/man/man1

	sudo mkdir -p  /etc/due
	sudo cp         ./etc/due/due.conf /etc/due

	sudo mkdir -p  /usr/share/due
	sudo cp -r      ./templates        /usr/share/due
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
orig.tar:
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Building DUE source tar file: $(DUE_ORIG_TAR)                #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	$(Q) git archive --format=tar.gz --prefix=due_$(DUE_VERSION)/  -o ../$(DUE_ORIG_TAR)  master
	@echo "  Produced tar file [ $(DUE_ORIG_TAR) ]in parent directory."
	$(Q) ls -lrt ../*.gz
	@echo ""
	$(Q) touch $@


# Create upstream tarball and build DUE .deb file from debian/master branch
# changing branches as needed.
debian-package: orig.tar
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Building DUE Debian installer package.                             #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	@echo "# Stashing any local Git changes."
	$(Q) git stash 
	@echo "# Checking out debian-test branch."
	$(Q) git checkout debian-test
	@echo ""
# Keep the option to extract master tarball in to a directory of
# strictly Debian files. This would be used only during testing
# development packaging builds, since the debian/master branch
# contains snapshots of the versions of DUE files that have been
# upstreamed, and will only be updated during upstreaming efforts.
#	@echo "# Extracting tarball."
	$(Q) tar -xvf ../due_*orig.tar.gz --strip-components=1
	@echo "# Select a Debian package build container."
	$(Q) ./due --duebuild --build-command dpkg-buildpackage -us -uc
	@echo ""
	@echo "# Deleting files extracted from tar archive."
	$(Q) git clean -xdf
	@echo "# Resetting debian/master branch."
	$(Q) git reset --hard
	@echo "# Checking out master branch."
	$(Q) git checkout master
	@echo "# Applying any local master branch stash changes with git stash pop."
#Use - to ignore errors if nothing pops, and ||: to avoid warnings if nothing to pop.
	- $(Q) git stash pop ||:
	@echo "# Parent directory build products:"
	@echo "# --------------------------------"
	$(Q) ls -lrt ..
	@echo ""
	@echo "# Done."
	@echo ""


debian: orig.tar
	@ echo "Building DUE Debian installer package."
	@ git checkout debian/master
	@ ./due --build

test:
	@echo "Due version $(DUE_VERSION)"
	@echo "Docker to install $(DOCKER_TO_INSTALL)"
	@echo "Host os $(HOST_OS)"
