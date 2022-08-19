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
# The cudos_version variable needs to be set in the environment
#
# It is used to
# - select the github tags to set when cloning the software
# - tag the tarball
# - set in the rpmbuild that creates the binaries
# - Set as the "version" response in "cudos-noded"
#

if [ "$cudos_version" = "" ]
then
    echo "Error: 'cudos_version' variable unset"
    exit 1
fi

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
# Define tarball creation function
create_cudos_tarball()
{
    VER="$1"

    # Clear out any existing git checkouts
    rm -rf Cudos*

    # Check out fresh copies of the current version
    case $VER in

    1\.1\.0)
      git clone --depth 1 --branch cudos-dev https://github.com/CudoVentures/cudos-node.git CudosNode
      git clone --depth 1 --branch cudos-dev https://github.com/CudoVentures/cudos-builders.git CudosBuilders
      git clone --depth 1 --branch cudos-dev https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
      ;;

    0\.4)
      git clone --depth 1 --branch v0.4.0 https://github.com/CudoVentures/cudos-node.git CudosNode
      git clone --depth 1 --branch v0.3.3 https://github.com/CudoVentures/cudos-builders.git CudosBuilders
      git clone --depth 1 --branch v0.4.0 https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
      git clone                           https://github.com/CudoVentures/cudos-network-upgrade.git CudosNetworkUpgrade
      ;;

    0\.[5-9]\.[0-9])
      git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cudos-node.git CudosNode
      git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cudos-builders.git CudosBuilders
      git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
      ;;
      
    [1-9]\.[0-9]\.[0-9])
      git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cudos-node.git CudosNode
      git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cudos-builders.git CudosBuilders
      git clone --depth 1 --branch v$VER https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
      ;;
      
    1.0.master)
      git clone --depth 1 --branch cudos-master https://github.com/CudoVentures/cudos-node.git CudosNode
      git clone --depth 1 --branch cudos-master https://github.com/CudoVentures/cudos-builders.git CudosBuilders
      git clone --depth 1 --branch cudos-master https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
      ;;
      
    1.0.dev)
      git clone --depth 1 --branch cudos-dev https://github.com/CudoVentures/cudos-node.git CudosNode
      git clone --depth 1 --branch cudos-dev https://github.com/CudoVentures/cudos-builders.git CudosBuilders
      git clone --depth 1 --branch cudos-dev https://github.com/CudoVentures/cosmos-gravity-bridge.git CudosGravityBridge
      ;;
      
    *)
      echo "Unknown Version '$VER'"
      exit 1
      ;;
      
    esac

    tar czf SOURCES/cudos-noded-${VER}.tar.gz Cudos*
    rm -rf Cudos*
}

# Define a utility function for rpmbuild
run_rpmbuild()
{
  VER=$1
  RLS=$2
  SPEC_NAME=$3
  
  echo -ne "\n\n======= Building Package $SPEC_NAME =======\n\n"
  
  rpmbuild \
     --define "_topdir $( pwd )" \
     --define "_versiontag ${VER}" \
     --define "_releasetag ${RLS}" \
     -bs $( pwd )/SPECS/${SPEC_NAME}.spec
  
  rpmbuild \
     --define "_topdir $( pwd )" \
     --define "_versiontag ${VER}" \
     --define "_releasetag ${RLS}" \
     --rebuild $( pwd )/SRPMS/${SPEC_NAME}-${VER}-${RLS}.*.src.rpm
}

# Define toml config tarball function
create_toml_tarball()
{
  FILETAG="$1"
  NTWK="$2"

  mkdir -p toml-tmp
  cd toml-tmp
  wget "https://github.com/CudoVentures/cudos-builders/blob/cudos-master/docker/config/genesis.${FILETAG}.json?raw=true"                  -O genesis.json
  wget "https://github.com/CudoVentures/cudos-builders/blob/cudos-master/docker/config/persistent-peers.${FILETAG}.config?raw=true"       -O persistent-peers.config
  wget "https://github.com/CudoVentures/cudos-builders/blob/cudos-master/docker/config/seeds.${FILETAG}.config?raw=true"                  -O seeds.config
  wget "https://github.com/CudoVentures/cudos-builders/blob/cudos-master/docker/config/state-sync-rpc-servers.${FILETAG}.config?raw=true" -O state-sync-rpc-servers.config
  touch unconditional-peers.config
  touch private-peers.config
  tar czvf ../SOURCES/toml-config-${NTWK}.tar.gz *
  cd ..
  rm -rf toml-tmp
}

#
# Clear out the old RPM binary files and the old BUILDROOT
#
rm -rf RPMS BUILDROOT || true

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
# Create the source tarballs
#
create_cudos_tarball "0.8.0"
create_cudos_tarball "0.9.0"
create_cudos_tarball "1.0.0"

#
# Create the toml config tarballs
#
create_toml_tarball "testnet.private" "private-testnet"
create_toml_tarball "testnet.public"  "testnet"
create_toml_tarball "mainnet"         "mainnet"

#
# Build the spec files
#
run_rpmbuild "1.0.0"            "${BUILD_NUMBER}" cosmovisor
run_rpmbuild "11.0.0"           "${BUILD_NUMBER}" osmosisd
run_rpmbuild "11.0.0"           "${BUILD_NUMBER}" osmosisd-v11.0.0
run_rpmbuild "${cudos_version}" "${BUILD_NUMBER}" cudos-network-private-testnet
run_rpmbuild "${cudos_version}" "${BUILD_NUMBER}" cudos-network-public-testnet
run_rpmbuild "${cudos_version}" "${BUILD_NUMBER}" cudos-network-mainnet
run_rpmbuild "0.8.0"            "${BUILD_NUMBER}" cudos-noded-v0.8.0
run_rpmbuild "0.9.0"            "${BUILD_NUMBER}" cudos-noded-v0.9.0
run_rpmbuild "1.0.0"            "${BUILD_NUMBER}" cudos-noded-v1.0.0
run_rpmbuild "1.1.0"            "${BUILD_NUMBER}" cudos-noded-v1.1.0
run_rpmbuild "${cudos_version}" "${BUILD_NUMBER}" cudos-noded

#
# Feed the rpm binaries into "Alien" to be converted
# to Debian packages
#
mkdir -p debian
cd debian
for FNM in ../RPMS/*/*.rpm
do
   echo -e "\n\nConverting rpm file $FNM to deb package\n\n"
   sudo alien --to-deb --keep-version --scripts $FNM
done
cd ..

#
# Pull the rpm backage information into .txt files
# Pull the file list form the packages into .lst.txt files
#
# These are usesful to store alongside the packages themselves in artifact lists
# So the content and info can easily be opened in the artifact list and viewed
#
for RPMFILE in RPMS/*/*.rpm
do
	rpm -qip $RPMFILE > ${RPMFILE}.txt
	rpm -qlp $RPMFILE > ${RPMFILE}-lst.txt
done
