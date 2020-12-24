#!/usr/bin/make -f

# Set the version in libdue as the source of truth
DUE_VERSION := $(shell /bin/sh -c "grep -o 'DUE_VERSION=\".*\"' ./libdue | sed -e 's/DUE_VERSION=//g' | tr -d \\\" " )

# Uncomment the following to enable more makefile output
#export DH_VERBOSE = 1

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

#
# Store phony build targets in a variable so they can be
# printed as part of help.
#
PHONY = help docs depends host-install uninstall orig.tar debian-package test no-make-default

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
	$(Q) echo " Make with V=1 for makefile debug."
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
	@echo "#   bsdutils git rsync docker.io jq curl                             #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	$(Q) if [ -f /etc/redhat-release ]; then \
		echo "Installing dependencies for Red Hat Linux" ;\
		sudo dnf install $(DUE_DEPENDENCIES) docker ;\
	else \
		echo "Installing dependencies for Debian Linux" ; \
		sudo apt-get install $(DUE_DEPENDENCIES ) bsdutils docker.io ; \
	fi
	@ echo "Done installing dependencies."

install: depends
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Installing DUE                                                     #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""

	sudo cp        ./due /usr/bin
	sudo cp        ./libdue /usr/lib
	sudo cp        ./docs/due.1 /usr/share/man/man1

	sudo mkdir -p  /etc/due
	sudo cp       ./etc/due/due.conf /etc/due

	sudo mkdir -p /usr/share/due
	sudo cp -r   ./templates /usr/share/due
	sudo cp -r   ./README.md /usr/share/due

	@ echo "Finally, add yourself to the user group with: sudo /usr/sbin/usermod -a -G docker $(shell whoami)"
	@echo ""

uninstall:
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Uninstalling DUE                                                   #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	sudo rm        /usr/bin/due
	sudo rm        /usr/lib/libdue
	sudo rm        /usr/share/man/man1/due.1

	sudo rm -rf   /etc/due
	sudo rm -rf   /usr/share/due

orig.tar:
ifneq ($(wildcard $(DEBIAN_BUILD_BRANCH)),)
	@echo "Check out the master branch to create orig.tar."
else
	$(Q) git archive --format=tar.gz --prefix=due_$(DUE_VERSION)/  -o ../due_$(DUE_VERSION).orig.tar.gz  master
	@echo "Produced tar file in parent directory."
	$(Q) ls -lrt ../*.gz
endif

debian-package: orig.tar
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# Building DUE Debian installer package.                             #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	@echo "# Checking out debian/master branch."
	$(Q) git checkout debian/master
	@echo ""
	@echo "# Select a Debian package build container."
	$(Q) ./due --build
	@echo ""
	@echo "# Checking out master branch."
	$(Q) git checkout master

test:
	@echo "Due version $(DUE_VERSION)"
