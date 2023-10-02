#!/bin/bash -xe
#
# Copyright 2022 Andrew Meredith <andrew.meredith@cudoventures.com>
# Copyright 2022 Cudo Ventures - All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
# As the correlation between the overall version tag and the tags within the repository
# has varied over time, and to include the development branches in the build mechanism
# this CASE is used to fetch the correct githun tags for the version indicated by the
# "$cudos_version" environment variable.
#
# It is intended for use as a step in a CI/CD chain to solidify the sources into a tarball in
# the conventional location in the rpmbuild tree structure ie ./SOURCES/
#

#
# # Define tarball creation function
# create_cudos_tarball()
# {
#     VER="$1"
# 
#     echo -e "\n\nCreating $VER Cudos tarball\n\n"
# 
#     # Clear out any existing git checkouts
#     rm -rf Cudos*
# 
#     # Silence the warning
#     git config --global advice.detachedHead false
#     
#     # Check out fresh copies of the current version
#     case $VER in
# 
#     1.0.1)
#       git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cudos-node.git CudosNode
#       git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cudos-builders.git CudosBuilders
#       git clone --depth 1 --branch v1.0.0 https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
#       ;;
#       
#     [0-9]\.[0-9]\.[0-9]\.[0-9])
#       git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cudos-node.git CudosNode
#       git clone --depth 1 --branch v1.0.0 https://github.com/CudoVentures/cudos-builders.git CudosBuilders
#       git clone --depth 1 --branch v1.0.0 https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
#       ;;
#       
#     [0-9]\.[0-9]\.[0-9])
#       git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cudos-node.git CudosNode
#       git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cudos-builders.git CudosBuilders
#       git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
#       ;;
#       
#     1.0.master)
#       git clone --depth 1 --branch cudos-master https://github.com/CudoVentures/cudos-node.git CudosNode
#       git clone --depth 1 --branch cudos-master https://github.com/CudoVentures/cudos-builders.git CudosBuilders
#       git clone --depth 1 --branch cudos-master https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
#       ;;
#       
#     1.0.dev)
#       git clone --depth 1 --branch cudos-dev https://github.com/CudoVentures/cudos-node.git CudosNode
#       git clone --depth 1 --branch cudos-dev https://github.com/CudoVentures/cudos-builders.git CudosBuilders
#       git clone --depth 1 --branch cudos-dev https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
#       ;;
#       
#     *)
#       echo "Unknown Version '$VER'"
#       exit 1
#       ;;
#       
#     esac
# 
#     tar czf SOURCES/cudos-noded-${VER}.tar.gz Cudos*
#     rm -rf Cudos*
# }

# Define toml config tarball function
create_toml_tarball()
{
  FILETAG="$1"
  NTWK="$2"

  echo -e "\n\nCreating TOML tarball '$FILETAG'\n\n"

  mkdir -p toml-tmp
  cd toml-tmp
  wget -4 -q "https://github.com/CudoVentures/cudos-builders/blob/cudos-master/docker/config/genesis.${FILETAG}.json?raw=true"                  -O genesis.json
  wget -4 -q "https://github.com/CudoVentures/cudos-builders/blob/cudos-master/docker/config/persistent-peers.${FILETAG}.config?raw=true"       -O persistent-peers.config
  wget -4 -q "https://github.com/CudoVentures/cudos-builders/blob/cudos-master/docker/config/seeds.${FILETAG}.config?raw=true"                  -O seeds.config
  wget -4 -q "https://github.com/CudoVentures/cudos-builders/blob/cudos-master/docker/config/state-sync-rpc-servers.${FILETAG}.config?raw=true" -O state-sync-rpc-servers.config
  touch unconditional-peers.config
  touch private-peers.config
  tar czvf ../SOURCES/toml-config-${NTWK}.tar.gz *
  cd ..
  rm -rf toml-tmp
}


# Define a utility function for rpmbuild
run_rpmbuild()
{
  VER=$1
  RLS=$2
  SPEC_NAME=$3
  
  echo -ne "\n\n======= Building Package $SPEC_NAME =======\n\n"
  
  # Take the spec file and ONLY package it into a source
  # rpm, do not actually build anything.
  rpmbuild \
     --define "_topdir $( pwd )" \
     --define "_versiontag ${VER}" \
     --define "_releasetag ${RLS}" \
     -bs $( pwd )/SPECS/${SPEC_NAME}.spec
  
  # Building these applications pulls in git repositories, some
  # of which have set file and directory permissions as read only
  # so when you go to delete them, the build job fails.
  if [[ -d buildtmp ]]
  then
    chmod -R +rwx buildtmp
  fi
 
  # Clean out the build area just in case, for some
  # reason, it didn't get cleaned last time
  rm -rf buildtmp
  
  # If $GO_BIN_DIR is set, add it to the front of the $PATH
  if [[ "${GO_BIN_DIR}" != "" ]]
  then
    echo -ne "  Info: Selecting Go binary path: ${GO_BIN_DIR}\n"
    export PATH="${GO_BIN_DIR}:${PATH}"
  fi
 
  # Set the _topdir to the freshly cleaned out build area
  # pull the source rpm that has just been built into
  # the clean build area, unpack it, and build the contents.
  #
  # NB This might seem a "round the houses" way of doing it,
  # but it firmly ensures that the payload of the src.rpm is complete
  # ensuring that an end user can build the package with just
  # the src.rpm
  #
  # The removal of __brp_check_rpaths is needed as there are some
  # .. "non standard" uses of this feature in the packages
  #
  rpmbuild \
     --define "_topdir $( pwd )/buildtmp" \
     --define "_versiontag ${VER}" \
     --define "_releasetag ${RLS}" \
     --define "__brp_check_rpaths %{nil}" \
     --rebuild $( pwd )/SRPMS/${SPEC_NAME}-${VER}-${RLS}.*src.rpm

  # Synchronise the RPMS directory in the clean build area back to
  # the master RPMS directory structure.
  rsync -var buildtmp/RPMS/. RPMS/.

  # Clean up
  chmod -R +rwx buildtmp
  rm -rf buildtmp
}

# define utility to loop through the rpm builds
#
# NB The chain data files sometimes use "v1.2.3" and sometime just "1.2.3"
# so this function needs to remove and then if needed re-add the v to make sure it is
# consistent
#
# NB rpm packaging cannot have a "-" in the version so "-rc" versions cannot be done this way
# although it is acceptable in a package name of course so the binary package names can be like
#   cudos-noded-v1.2.3-rc4 
# but not
#   cudos-noded-v1.2.3-rc4 version 1.2.3-rc4
#
build_project_from_chain_data()
{
  CHAIN_NAME="$1"
  TMPFILE=/tmp/build.sh.$$

  # Grab the chain data
  curl -4 -s https://raw.githubusercontent.com/cosmos/chain-registry/master/${CHAIN_NAME}/chain.json -o "${TMPFILE}"

  # Use the local copy to divine specific values for that chain
  CHAIN_NAME="$( cat $TMPFILE | jq .chain_name | tr -d '"' )"
  DAEMON_NAME="$( cat $TMPFILE | jq .daemon_name | tr -d '"' )"
  PRETTY_NAME="$( cat $TMPFILE | jq .pretty_name | tr -d '"' )"
  SYSTEM_VER="$( cat $TMPFILE | jq .codebase.recommended_version | tr -d '"v' )"
  COMPATIBLE_VERSIONS="$( cat $TMPFILE | jq .codebase.compatible_versions | tr -d '"v' | grep '[0-9]' )"

  # Chain Data Workaround Kludges :-)
  #
  # Ideally the chain data would be absolutely accurate, complete and up to date.
  # In case that is for some reason not the case .. or an update is to be tested in dev
  # here's where the variances go
  #
  case "$CHAIN_NAME" in
    cudos)
      DAEMON_NAME="cudos-noded"
      SYSTEM_VER="1.1.0"
      COMPATIBLE_VERSIONS="0.8.0 0.9.0 1.0.1 1.1.0"
      ;;
    osmosis)
      SYSTEM_VER="19.2.0"
      COMPATIBLE_VERSIONS="11.0.0 12.3.0 13.0.0-rc5 14.0.0 15.0.0 15.2.0 16.1.0 16.1.2 17.0.0 18.0.0 19.0.0 19.2.0"
      ;;
    cosmoshub)
      SYSTEM_VER="9.0.1"
      COMPATIBLE_VERSIONS="7.1.1 8.0.1 9.0.1"
      ;;
  esac
  
  # Clean up
  rm -f "${TMPFILE}"

  # Build the daemon framework package, named for the daemon_name at the recommended_version
  run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" ${DAEMON_NAME}
  
  # For every "compatible_version", build a binary package named for that version
  # and the package version of "recommended_version"
  #
  # Unfortuneately, Go version is a tripwire as some versions of Cosmos daemons need specific Go versions
  # and will cause binariaes to emit hash failures if a lower or higher Go version is used. There is no
  # standard mechanism for handling multiple Go versions, so the following has been adopted for
  # this build system.
  #   - Unpack the go binary tarball to /usr/local
  #   - Rename /usr/local/go to /usr/local/go-<go version>
  #   - For best version separatoin do not provide a system default Go path
  #   - Add the Go bin directory to the  
  for BUILD_VERSION in ${COMPATIBLE_VERSIONS}
  do
    # Select specific Go versions by chain and version
    case $CHAIN_NAME in
    	
      cudos)
      case ${BUILD_VERSION} in
        [01].* )
          export GO_VER="1.18.3"
          ;;
      esac
      ;;

    osmosis)
      case ${BUILD_VERSION} in
        1[6-9].* )      
          export GO_VER="1.20.8"
          ;;
        1[4-5].* )
          export GO_VER="1.19.6"
          ;;

        1[0-3].* )
          export GO_VER="1.18.3"
          ;;
      esac
      ;;

    cosmoshub)
      case ${BUILD_VERSION} in
        * )
          export GO_VER="1.18.3"
          ;;
      esac
      ;;
      
    esac
  
    # Set GO_BIN_DIR off GO_VER
    if [[ "${GO_VER}" != "" ]]
    then
      export GO_BIN_DIR="/usr/local/go-${GO_VER}/bin"
      echo -ne "  Info: GO_BIN_DIR = ${GO_BIN_DIR}\n"
    else
      export GO_VER="1.18.3"
      echo -ne "  Warning: GO_VER is not set, setting default (${GO_VER})\n"    
    fi
      
    # Execute the build function above
    run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" ${DAEMON_NAME}-v${BUILD_VERSION}
  done
}

#
# Create config tarballs from local repo files
#
cd SOURCES
for FDIR in *-network-*_config
do
  echo -e "\n\nCreating $FDIR tarball\n\n"
  tar -C "${FDIR}" -czvf "${FDIR}.tar.gz" .
done
cd ..

#
# Clear out the old RPM binary files and the old BUILDROOT
#
sudo rm -rf debian RPMS BUILDROOT || true

#
# BUILD_NUMBER can be inherited from the CI/CD environment and
# represent the serial number of that build for traceability
#
# If unset, tag it with the hostname and datestamp
#
# This is used as
# - The "release_tag" in the rpm packaging
# - The minor release embeded in the cudos-noded binary
#
if [ "$BUILD_NUMBER" = "" ]
then
  BUILD_NUMBER="$( hostname -s ).$( date '+%Y%m%d%H%M%S' )"
fi

#
# Copy files up to SOURCES for packaging in src.rpms
#
cp -v README.md  SOURCES
cp -v cudos.repo SOURCES

#
# Create the cudos-noded source tarballs
#
#create_cudos_tarball "0.8.0"
#create_cudos_tarball "0.9.0"
#create_cudos_tarball "1.0.0"
#create_cudos_tarball "1.0.1"
#create_cudos_tarball "1.1.0.1"

#
# Create the toml config tarballs
#
# create_toml_tarball "testnet.private" "private-testnet"
create_toml_tarball "testnet.public"  "testnet"
create_toml_tarball "mainnet"         "mainnet"

#
# Build cosmovisor Project
#
export DAEMON_NAME="cosmovisor"
export SYSTEM_VER="1.1.0"

run_rpmbuild "1.0.0" "${BUILD_NUMBER}" "${DAEMON_NAME}"

#
# Build Release package
#
run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" cudos-release

#
# Build Cudos Project
#

build_project_from_chain_data cudos

run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" cudos-network-private-testnet
run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" cudos-network-public-testnet
run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" cudos-network-mainnet

#
# Build Osmosis Project
#
build_project_from_chain_data osmosis

run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" osmosis-network-mainnet
run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" osmosis-network-testnet

#
# Build Gaia/Cosmos Hub Project
#
build_project_from_chain_data cosmoshub

run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" cosmoshub-network-mainnet
run_rpmbuild "${SYSTEM_VER}" "${BUILD_NUMBER}" cosmoshub-network-testnet

#
# Feed the rpm binaries into "Alien" to be converted
# to Debian packages
#
# This section also edits in the dependancies which
# alien leaves out
#
mkdir -p debian
cd debian
for FNM in ../RPMS/*/*.rpm
do
   echo -e "\n\nConverting rpm file $FNM to deb package\n\n"
   DEPS="$( rpm -q --requires $FNM | fgrep -v / | fgrep -v '(' | tr '\n' ',' | sed -e's/,$//' )"
   OBSOLETES="$( rpm -q --obsoletes $FNM | fgrep -v / | fgrep -v '(' | tr '\n' ',' | sed -e's/,$//' )"
   DIRNAME="$( rpm -q --queryformat '%{NAME}-%{VERSION}' $FNM || true )"

   echo "Deps: $DEPS"
   echo "Directory: $DIRNAME"

   sudo alien --generate --to-deb --keep-version --scripts $FNM
   sudo sed -i -e's/^Depends:.*/&'",${DEPS}/" ${DIRNAME}/debian/control
   echo -ne "Replaces: ${OBSOLETES}\nConflicts: ${OBSOLETES}\n" | sudo tee -a ${DIRNAME}/debian/control
   cd $DIRNAME
   sudo debian/rules binary
   cd ..
   sudo rm -rf "$DIRNAME"
done
cd ..

#
# Pull the rpm package information into .txt files
# Pull the file lists from the packages into .lst.txt files
#
# These are usesful to store alongside the packages themselves in artifact lists
# So the content and info can easily be opened in the artifact list and viewed
#
for RPMFILE in RPMS/*/*.rpm
do
  rpm -qip $RPMFILE > ${RPMFILE}.txt
  rpm -qlp $RPMFILE > ${RPMFILE}-lst.txt
done
