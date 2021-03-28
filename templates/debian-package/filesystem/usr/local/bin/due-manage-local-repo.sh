#!/bin/bash
# SCRIPT_PURPOSE:  manage a local Debian package repository

# DUE_VERSION_COMPATIBILITY_TRACKING=2.0.0

# Copyright 2020,2021 NVIDIA Corporation. All rights reserved.
#
#  SPDX-License-Identifier:     MIT

# provide a version for use in upgrades
SCRIPT_VERSION="1.0"

if [ "$gTOP_DIR" = "" ];then
    gTOP_DIR=$(pwd)
fi


# if this is set as the first argument, enable debug trace
if [ "$1" = "--script-debug" ];then
    set -x
    echo "$0 Enabling --script-debug "
fi

# Top level help
function fxnHelp()
{
    echo""
    echo "Usage  : $(basename "$0"): --name <reponame> [OPTIONS]"
    echo ""
    echo " OPTIONS:"
    echo "   --name <reponame>          Specify repo name to use. New repos should have unique names."
    echo "   --create-repo              Create empty local repository."
    echo "     --architecture <arch>    Architecture type for repository. Default: [ $USE_ARCHITECTURE ]"
    echo "   --delete-repo              Remove all traces of --name <repo>"
    echo "   --update-repo              Rebuild index of current repo contents."
    echo ""
    echo "   --add <deb or dir of debs> Add deb file or directory holding debs to repository."
    echo "                               For multiple single debs, repeat --add."
    echo "                                Ex: --add foo.deb --add bar.deb"
    echo "   --delete-package <term>    Remove <term> from repo."
    echo "                               If '<term>' wildcards can be passed. See --help-examples."
    echo ""
    echo "   --disable-repo             Remove apt files referencing <reponame>, but keep the repository."
    echo "   --enable-repo              Set apt files to reference <reponame>."
    echo "   --no-apt-update            Skip default behavior of apt-updating on exit."
    echo ""
    echo " Information:"
    echo "   --list-repo                Print contents of local repo."
    echo "   --version                  Version of this script."
    echo "   --help                     This message"
    echo "   --help-examples            Print possible configurations."

    echo ""
}

# Examples of use
function fxnHelpExamples()
{
    local userIs="$(whoami)"

    echo "Examples:"
    echo ""
    echo " Create repository foo:"
    echo "   $0 --name /home/${userIs}/foo --create-repo"
    echo ""
    echo " Create repository foo using packages in ~/pkgdir... "
    echo "   ...and make it active with  /etc/apt/sources.list.d/${LOCAL_REPO_SOURCES_LIST}:"
    echo "   $0 --name /home/${userIs}/foo --create-repo --add /home/${userIs}/pkgdir --enable-repo"
    echo ""
    echo " Add a package(s) or directory of packages:"
    echo "   $0 --name /home/${userIs}/foo -add foo.deb --add bar.deb"
    echo "   $0 --name /home/${userIs}/foo -add ./mydebs/"
    echo ""
    echo " Delete package bar.deb from repository:"
    echo "   $0 --name /home/${userIs}/foo --delete-package bar.deb"
    echo " Delete all packages starting with baz (note the single quotes!):"
    echo "   $0 --name /home/${userIs}/foo --delete-package 'baz*'"
    echo ""
    echo " Delete repository foo:"
    echo "   $0 --name /home/${userIs}/foo --delete-repo"
    echo""

}

# Somewhat formatted status messages
function fxnPP()
{
    echo "== $*"
}

function fxnWARN()
{
    echo ""
    echo "## Warning:  $*"
    echo ""
}
# A universal error checking function. Invoke as:
# fxnEC <command line> || exit 1
# Example:  fxnEC cp ./foo /home/bar || exit 1
function fxnEC ()
{
    # actually run the command
    "$@"

    # save the status so it doesn't get overwritten
    status=$?
    # Print calling chain (BASH_SOURCE) and lines called from (BASH_LINENO) for better debug
    if [ $status -ne 0 ];then
        echo "ERROR [ $status ] in $(caller 0), calls [ ${BASH_LINENO[*]} ] command: \"$*\"" 1>&2
    fi

    return $status
}

# Standardized error messaging
# Line numbers are more of a suggestion than a rule
function fxnERR
{
    # Print script name, and line original macro was on.
    printf "ERROR at $(caller 0)  :  %s\\n" "$1"
    echo ""
}

# Takes:  Path to deb, or directory holding *.deb to add to repository
function fxnAddRepositoryPackage()
{
    local toAdd="$1"

    for debFile in $toAdd ; do
        if [ ! -e "$debFile" ];then
            fxnERR "Failed to find [ $debFile ] to add to local repository. Exiting."
            exit 1
        fi

        if [ -d "$debFile" ];then
            fxnPP "Copying ${debFile}/*.deb to $REPO_POOL_DIR"
            fxnEC cp -f "${debFile}/"*.deb "$REPO_POOL_DIR" || exit 1
        elif [ -f "$debFile" ];then
            fxnPP "Copying [ $debFile ] to $REPO_POOL_DIR"
            fxnEC cp -f "$debFile" "$REPO_POOL_DIR" || exit 1

        else
            fxnERR "Could not find [ $debFile ] to add to local package repository."
            exit 1
        fi
    done
    # refresh Package files
    fxnUpdateRepository

    fxnListRepoPool

    # With packages in, apt updates are safe.
    DO_APT_UPDATE="TRUE"


}

# Takes: name of package to delete
#         will take wildcard.
function fxnDeleteRepositoryPackage()
{
    echo "Attempting to delete [ $1 ] from the repository."

    if [ ! -e "$REPO_POOL_DIR" ];then
        fxnERR "Failed to find pool directory [ $REPO_POOL_DIR ]. Exiting."
        exit 1
    fi

    # Express argument as $@ to expand wildcards here.
    rm "${REPO_POOL_DIR}"/$@
    if [ $? != 0 ];then
        echo "Failed to delete [ $1 ]."
        echo "Exiting."
        DO_APT_UPDATE="FALSE"
    else
        # Since that worked, update the repository
        fxnUpdateRepository
        echo "Deleted: [ $1 ]"
    fi

    # And let the user see the results
    fxnListRepoPool
    echo ""

}

#
# Update the package database/index files after the contents have changed.
#
function fxnUpdateRepository()
{

    # If this is an initialization, Packages won't exist as the repository is empty
    if [ -e "${LOCAL_REPOSITORY_BIN_DIR}/Packages" ];then
        # Otherwise clean them out to get updated
        fxnPP "Removing OLD Package index files before update."
        fxnEC rm "${LOCAL_REPOSITORY_BIN_DIR}/Packages"    || exit 1
        fxnEC rm "${LOCAL_REPOSITORY_BIN_DIR}/Packages.gz" || exit 1
        fxnEC rm "${LOCAL_REPOSITORY_BIN_DIR}/Release"     || exit 1
    fi

    curDir=$(pwd)

    cd "$LOCAL_PACKAGE_REPOSITORY_ROOT" || exit 1

    fxnPP "Updating local repository at [ $LOCAL_PACKAGE_REPOSITORY_PATH ]"
    #   fxnEC apt-ftparchive --arch $USE_ARCHITECTURE  packages pool |
    fxnEC apt-ftparchive packages pool | \
        tee "${LOCAL_REPOSITORY_BIN_DIR}"/Packages | \
        gzip > "${LOCAL_REPOSITORY_BIN_DIR}"/Packages.gz  || exit 1

    # Options to supply to the release file
    optionList=" -o APT::FTPArchive::Release::Origin=DUE-duebuild \
-o APT::FTPArchive::Release::Label=localPackageRepository \
-o APT::FTPArchive::Release::Suite=local-repo \
-o APT::FTPArchive::Release::Version=1.0 \
-o APT::FTPArchive::Release::Codename=$RELEASE_NAME \
-o APT::FTPArchive::Release::Architectures=$USE_ARCHITECTURE \
-o APT::FTPArchive::Release::Description=LocalPackageRepository \
-o APT::FTPArchive::Release::Components=main"

    # release under dists/local-due-repo/main/binary-amd64
    fxnPP "Creating Release file under ${LOCAL_REPOSITORY_BIN_DIR}"
    apt-ftparchive release "${LOCAL_REPOSITORY_BIN_DIR}" > \
                   "${LOCAL_REPOSITORY_BIN_DIR}"/Release

    # Top level release file under dists/local-due-repo
    fxnPP "Creating Release file under ${LOCAL_PACKAGE_REPOSITORY_ROOT}/dists/${LOCAL_REPOSITORY_DISTRIBUTION}"
    apt-ftparchive $optionList release "${LOCAL_PACKAGE_REPOSITORY_ROOT}/dists/${LOCAL_REPOSITORY_DISTRIBUTION}/" > \
                   "${LOCAL_PACKAGE_REPOSITORY_ROOT}/dists/${LOCAL_REPOSITORY_DISTRIBUTION}/Release"

    cd "$curDir" || exit 1

}


#Takes: ENABLE or DISABLE
#Does:  adds or removes local repository sources.list file, and
#       apt updates
function fxnManageAPTConfig()
{

    local localRepoSourcesList=""
    #
    # Sanity check that a valid reposiory was passed.
    #
    if [  -e "$LOCAL_PACKAGE_REPOSITORY_ROOT" ];then
        if [  ! -e "$REPO_DEBS_DIR" ] || \
               [ ! -e "$REPO_POOL_DIR" ] || \
               [ ! -e "$LOCAL_REPOSITORY_BIN_DIR" ];then
            echo -e "\nFailed to find one of:\n [ $REPO_DEBS_DIR ]\n [ $REPO_POOL_DIR ]\n [ $LOCAL_REPOSITORY_BIN_DIR ]\n Try deleting and re-creating the repository? \n"
            fxnERR "Invalid repository [ $LOCAL_PACKAGE_REPOSITORY_ROOT ]"
            exit 1
        fi
    else
        fxnERR "Failed to find local repository at [ $LOCAL_PACKAGE_REPOSITORY_ROOT ] "
		if [ "$1" = "ENABLE" ];then
			# Cannot activate what is not there
			exit 1
		fi
		# Disable, however, is still possible if this is cleaning up a broken configuration.
    fi

    if [ "$1" = "ENABLE" ];then
        #
        # Always start clean. Could be a new enable for a new repo.
        #
        fxnManageAPTConfig "DISABLE" > /dev/null

        # Update the sources.list file
        localRepoSourcesList="${LOCAL_PACKAGE_REPOSITORY_ROOT}/${LOCAL_REPO_SOURCES_LIST}"
        if [ ! -e /etc/apt/sources.list.d/"${LOCAL_REPO_SOURCES_LIST}" ];then
            fxnPP "Creating sources.list file for local repository as: [ $localRepoSourcesList ]"

            echo "# Created by $(whoami) using $0 building from $(pwd) on $(date)" > "$localRepoSourcesList"
            echo "deb [arch=$USE_ARCHITECTURE trusted=yes] copy:${LOCAL_PACKAGE_REPOSITORY_ROOT}/ $LOCAL_REPOSITORY_DISTRIBUTION $LOCAL_REPOSITORY_COMPONENT" >> "$localRepoSourcesList"
            fxnPP "Adding   local repository sources.list to local /etc/apt/sources.list.d"
            fxnEC sudo cp "$localRepoSourcesList" /etc/apt/sources.list.d/ || exit 1
        else
            fxnPP "Local sources.list exists at /etc/apt/sources.list.d/${LOCAL_REPO_SOURCES_LIST}"
        fi # If no local sources list file


        # Pin the local packages to a higher than normal priority
        # View with: apt-cache policy
        # If making changes, force a refresh as follows:
        #   remove the entry under /etc/apt/sources.list.d/
        #   apt-get update
        #   restore the entry under /etc/apt/sources.list.d/
        if [ ! -e "$LOCAL_APT_PREFERENCES_FILE" ];then
            fxnPP "Setting  local repository priority high with: $LOCAL_APT_PREFERENCES_FILE"
            # Note that this only works if there is a Release file in the repo
            cat <<EOF > /tmp/apt-pref
# Created by $(whoami) using $0 building from $(pwd) on $(date)
Package: *
Pin: release n=$RELEASE_NAME
Pin-Priority: 990  >
EOF
            fxnEC sudo mv /tmp/apt-pref "$LOCAL_APT_PREFERENCES_FILE" || exit 1
        else
            fxnPP "Local repository has high priority with add of $LOCAL_APT_PREFERENCES_FILE"
        fi

        # If no packages have been added, the Packages, Packages.gz and Release
        # files will not exist, and APT will throw errors trying to find them.
        # Subsequent package adds will resolve this.
        if [ -e "${LOCAL_REPOSITORY_BIN_DIR}/Packages" ];then
            fxnPP "Updating..."
            fxnEC sudo apt-get update
        else
            fxnPP "Skipping APT update as no packages have been added yet, and 'Failed to stat' errors will be seen."
            fxnPP "Use $0 --name $LOCAL_REPO_NAME --add <deb or directory of debs> to add packages."
            DO_APT_UPDATE="FALSE"
            # At this point the sources.list and apt preferences files are set up to
            # reference and prioritize the local repository.
        fi

    fi  # if ENABLE

    if [ "$1" = "DISABLE" ];then
        if [ -e "$LOCAL_APT_PREFERENCES_FILE" ];then
            fxnPP "Removing [ $LOCAL_APT_PREFERENCES_FILE ]"
            sudo rm "$LOCAL_APT_PREFERENCES_FILE"
        else
            fxnPP "Done. No apt preferences file at  [ $LOCAL_APT_PREFERENCES_FILE ]."
        fi
        if [  -e /etc/apt/sources.list.d/"${LOCAL_REPO_SOURCES_LIST}" ];then
            fxnPP "Removing sources.list file from /etc/apt/sources.list.d/${LOCAL_REPO_SOURCES_LIST}"
            sudo rm "/etc/apt/sources.list.d/${LOCAL_REPO_SOURCES_LIST}"
            # Expect apt-get update as the script exits
            #            sudo apt-get update
        else
            fxnPP "Done. No sources.list file at     [ /etc/apt/sources.list.d/${LOCAL_REPO_SOURCES_LIST} ]."
        fi
    fi



}

# Takes: name of new package repository
# Does:  sets LOCAL_PACKAGE_REPOSITORY PATH and ROOT
function fxnSetPaths()
{
    local repoName="$1"

    if [ "$2" != "SKIP_REPO_EXISTS_CHECK" ];then
        # Repo creation code calls this, so do not exit before
        # it has had a chance to create the directory.
        if [ ! -e "$repoName" ];then
            fxnERR "Cannot find local repository [ $repoName ]. Exiting."
            exit 1
        fi
    fi
    #
    # Is the repository given as an absolute path?
    # (it starts with a '/' ?)
    if [[ $repoName == /* ]];then
        # An absolute path
        LOCAL_PACKAGE_REPOSITORY_PATH=$( realpath "${repoName}" )
        LOCAL_PACKAGE_REPOSITORY_ROOT="${repoName}"
        #        echo "Using ABSOLUTE  path to repository [ $LOCAL_PACKAGE_REPOSITORY_ROOT ]"
    else
        # A relative path. Drop it local.
        LOCAL_PACKAGE_REPOSITORY_PATH=$( realpath "${gTOP_DIR}" )
        LOCAL_PACKAGE_REPOSITORY_ROOT="${LOCAL_PACKAGE_REPOSITORY_PATH}/${repoName}"
        #        echo "Using RELATIVE path to repository [ $LOCAL_PACKAGE_REPOSITORY_ROOT ]"
    fi

    REPO_POOL_DIR="${LOCAL_PACKAGE_REPOSITORY_ROOT}/pool"
    REPO_DEBS_DIR="${LOCAL_PACKAGE_REPOSITORY_ROOT}/debs"

    # Location of binary specific section within the local repo
    LOCAL_REPOSITORY_BIN_DIR=${LOCAL_PACKAGE_REPOSITORY_ROOT}/dists/${LOCAL_REPOSITORY_DISTRIBUTION}/${LOCAL_REPOSITORY_COMPONENT}/binary-${USE_ARCHITECTURE}

}

# List contents of repository /pool directory
function fxnListRepoPool()
{
    echo ""
    echo " Contents of [ ${LOCAL_REPO_NAME}/pool ] directory:"
    echo ""
    ls -l "$REPO_POOL_DIR"
    # Don't waste time updating when nothing has changed.
    DO_APT_UPDATE="FALSE"
    echo ""


}

# Takes: name to use for repository
#        Debian package  architecture ( or 'default' to determine it from the system.)
#        absolute path to a directory that contains files to add to the repository

# Does:  Creates a local package repository one directory up from
#        the current build directory (or uses it if it already exists)
#        and adds it to the build.
function fxnCreateLocalPackageRepository()
{

    # Set paths and disable checking for the lack of a repository,
    # as we are about to address that...
    fxnSetPaths "$LOCAL_REPO_NAME" "SKIP_REPO_EXISTS_CHECK"

    if [ ! -e "$LOCAL_PACKAGE_REPOSITORY_ROOT" ];then
        fxnPP "Creating directories for local Debian package repository at: $LOCAL_PACKAGE_REPOSITORY_PATH"
        fxnEC mkdir "$LOCAL_PACKAGE_REPOSITORY_ROOT" || exit 1
        fxnPP "Creating $REPO_DEBS_DIR"
        fxnEC mkdir "$REPO_DEBS_DIR" || exit 1
        fxnPP "Creating $REPO_POOL_DIR"
        fxnEC mkdir "$REPO_POOL_DIR" || exit 1
        fxnPP "Creating $LOCAL_REPOSITORY_BIN_DIR"
        fxnEC mkdir -p "$LOCAL_REPOSITORY_BIN_DIR" || exit 1
    fi

    fxnManageAPTConfig "ENABLE"
    # No point in updating until packages have been added...
    DO_APT_UPDATE="FALSE"

    fxnPP "Created repository at: [ $LOCAL_PACKAGE_REPOSITORY_ROOT ]"
}


##################################################
#                                                #
# MAIN  - script processing starts here          #
#                                                #
##################################################

# unless specified otherwise, always update apt.
DO_APT_UPDATE="TRUE"

if [ "$#" = "0" ];then
    # Require an argument for action.
    # Always trigger help messages on no action.
    fxnHelp
    exit 0
fi

#
# Gather arguments and set action flags for processing after
# all parsing is done. The only functions that should get called
# from here are ones that take no arguments.
while [[ $# -gt 0 ]]
do
    term="$1"

    case $term in

        --script-debug )
            # Catch the debug flag here
            echo "[ $0 ] Script debug is ON"
            ;;

        --name )
            # specify name of repository to reference
            LOCAL_REPO_NAME="$2"
			# Create a name for the release from the name of the repository.
			RELEASE_NAME=$( basename $LOCAL_REPO_NAME )			
            shift
            ;;

        --create-repo )
            # Use (or create if it does not exist) a local Debian
            # package repository to hold build products, and serve
            # them for subsequent builds.
            # Useful when building packages that depend on previously
            # built packages.
            CREATE_LOCAL_REPO="TRUE"
            ;;

        --architecture )
            # Architecture type to use
            USE_ARCHITECTURE="$2"
            shift
            ;;

        --delete-repo )
            DELETE_LOCAL_REPO="TRUE"
            ;;

        --add )
            # add a package to a list of packages to add
            if [ ! -e "$2" ];then
                fxnERR "Failed to find [ $ADD_TO_REPO ] to add to local repository. Exiting."
                exit 1
            fi
            ADD_TO_REPO+=" $2 "
            shift
            ;;

        --delete-package )
            DELETE_REPOSITORY_PACKAGE="$2"
            shift
            ;;

        --list-repo )
            # List the repository contents
            DO_LIST_REPO="TRUE"
            ;;

        --disable-repo )
            # Remove local sources.list references
            DISABLE_APT_CONFIG="TRUE"
            ;;

        --enable-repo )
            # add local sources.list references
            ENABLE_APT_CONFIG="TRUE"
            ;;

        --no-apt-update )
            # Do not run apt-get update before exiting.
            # expect this to be the exception, not the rule.
            DO_APT_UPDATE="FALSE"
            ;;

        --version )
            # Track version for upgrade purposes
            echo "$SCRIPT_VERSION"
            exit 0
            ;;

        --update-repo )
            # Rebuild package files and update the repository. Put Apt files under /etc
            DO_UPDATE_REPOSITORY="TRUE"
            ;;

        -h|--help)
            fxnHelp
            exit 0
            ;;

        --help-examples)
            # Show examples of script invocation
            fxnHelpExamples
            exit 0
            ;;


        *)
            fxnHelp
            echo "Unrecognized option [ $term ]. Exiting"
            exit 1
            ;;

    esac
    shift # skip over argument

done

#
# Set repository values based on any user input
#


# Default to local architecture (set here as help uses it )
USE_ARCHITECTURE=$( dpkg-architecture --query DEB_TARGET_ARCH )
LOCAL_REPOSITORY_DISTRIBUTION="${RELEASE_NAME}"
LOCAL_REPOSITORY_COMPONENT="main"
LOCAL_REPO_SOURCES_LIST="due-local-${RELEASE_NAME}-repo.list"
LOCAL_APT_PREFERENCES_FILE="/etc/apt/preferences.d/10due-local-${RELEASE_NAME}-repo"

#
# As all other commands require the existence of a repository,
# the first option is to create one.
#
if [ "$CREATE_LOCAL_REPO" = "TRUE" ];then
    fxnCreateLocalPackageRepository "$LOCAL_REPO_NAME" "$USE_ARCHITECTURE"
fi


if [ "$DELETE_LOCAL_REPO" = "TRUE" ];then
	# Delete takes a slightly different set paths
	# Generate repo file names. Do not check for validity as
	# the repo may be gone, but apt config files still exist.
	fxnSetPaths "$LOCAL_REPO_NAME" "SKIP_REPO_EXISTS_CHECK"
	
    fxnPP "Removing local package repository [ $LOCAL_REPO_NAME ] and associated files."
    if [ -e "$LOCAL_REPO_NAME" ];then
        fxnPP "Deleting [ $LOCAL_REPO_NAME ]"
        rm -rf "$LOCAL_REPO_NAME"
    else
        # Print as message, not error as this has been handled.
        fxnPP "Done. No repository directory at  [ $LOCAL_REPO_NAME ]."
    fi
    # Clean up apt preferences/sources.list in case the repo
    # directory was manually deleted but these weren't.
    fxnManageAPTConfig "DISABLE"

	exit
fi

#
# Set paths to various locations and sanity check for this repository.
# Has to be after fxnCreateLocalRepository so that the script actually has
# a chance to make the repository before we sanity check for it's existence.
#
fxnSetPaths "$LOCAL_REPO_NAME"

if [ "$DO_UPDATE_REPOSITORY" = "TRUE" ];then
    fxnUpdateRepository
fi

if [ "$ENABLE_APT_CONFIG" = "TRUE" ];then
    # Add local sources.list references
    fxnManageAPTConfig "ENABLE"
fi

if [ "$DISABLE_APT_CONFIG" = "TRUE" ];then
    # Remove local sources.list references
    fxnManageAPTConfig "DISABLE"
fi

if [ "$ADD_TO_REPO" != "" ];then
    fxnAddRepositoryPackage "$ADD_TO_REPO"
fi

if [ "$DELETE_REPOSITORY_PACKAGE" != "" ];then
    fxnDeleteRepositoryPackage "$DELETE_REPOSITORY_PACKAGE"
fi

if [ "$DO_LIST_REPO" = "TRUE" ];then
    # Show contents of repository.
    fxnListRepoPool
fi


if [ "$DO_APT_UPDATE" = "TRUE" ];then
    fxnPP "Updating APT."
    sudo apt-get update
fi
