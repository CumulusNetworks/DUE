#!/usr/bin/make -f

DUE_VERSION = 1.6.3
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

# Manual page is generated from manpage-due-1.md via Pandoc
MAN_PAGE = docs/due.1



.PHONY: docs depends install

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
	@echo "#                                                                    #"	
	@echo "# Pandoc detected: updating documentation "
	@echo "# Removing existing $(MAN_PAGE) "
	rm $(MAN_PAGE)
	@echo "# Generating new man page from docs/manpage-due-1.md "
	pandoc --standalone --to man docs/manpage-due-1.md -o $(MAN_PAGE)
	@echo ""
	/bin/ls -lrt ./docs

	@echo "#                                                                    #"	
	@echo "#######################################################################"
	@echo ""
else
	@echo ""
	@echo "#######################################################################"
	@echo "# Pandoc is not installed. NOT regenerating due.1 man page            #"
	@echo "#                                                                    #"
	@echo "# If you want to update the man pages:                                #"
	@echo "#    apt-get install pandoc                                           #"
	@echo "# ...and retry this make -f debian/control docs                       #"
	@echo "#                                                                    #"
	@echo "#######################################################################"
	@echo ""
endif

depends:
	@echo "######################################################################"
	@echo "#                                                                    #"
	@echo "# DUE requires the following packages:                               #"
	@echo "#                                                                    #"
	@echo "#   bsdutils git rsync docker.io                                     #"
	@echo "#                                                                    #"
	@echo "######################################################################"
	@echo ""
	sudo apt-get install bsdutils git rsync docker.io

install:
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
	git archive --format=tar.gz   -o ../due-$(DUE_VERSION).orig.tar.gz  master
	@echo "Produced tar file in parent directory."
	ls -lrt ../*.gz 
