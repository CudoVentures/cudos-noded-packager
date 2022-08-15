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
# Runs the Cudos Node Daemon
#

Name:         cudos-noded-v0.9.0
Version:      %{_versiontag}
Release:      %{_releasetag}%{?dist}
Summary:      Cudos Node Binary Pack for v0.9.0

License:      GPL3
URL:          https://github.com/CudoVentures/cudos-node           
Source0:      cudos-noded-%{version}.tar.gz
Provides:     libwasmvm.so()(64bit)

# undefine __brp_mangle_shebangs
%global __brp_check_rpaths %{nil}

%description
Cudos Node binary and library

Installed into the Cosmovisor directories

%pre
getent group cudos >/dev/null || groupadd -r cudos || :
getent passwd cudos >/dev/null || useradd -c "Cudos User" -g cudos -s /bin/bash -r -m -d /var/lib/cudos cudos 2> /dev/null || :

%package -n cudos-node-v0.9.0-src
Summary: Cudos Node Sources
%description -n cudos-node-v0.9.0-src
CUDOS Node Sources

%prep
echo -e "\n\n=== prep section ===\n\n"
# Unpack tarball

BASEDR="$( pwd )"
tar xzf %{SOURCE0}

%build
echo -e "\n\n=== build section ===\n\n"
export GOPATH="${RPM_BUILD_DIR}/go"
cd CudosNode
make

%install
echo -e "\n\n=== install section ===\n\n"

# Make the fixed directory structure
mkdir -p ${RPM_BUILD_ROOT}/var/lib/cudos/src/v0.9.0/
mkdir -p ${RPM_BUILD_ROOT}/var/lib/cudos/cudos-data/cosmovisor/upgrades/v%{version}/bin/
mkdir -p ${RPM_BUILD_ROOT}/var/lib/cudos/cudos-data/cosmovisor/upgrades/v%{version}/lib/

# Copy the sources to /var/lib/cudos
cp -r ${RPM_BUILD_DIR}/Cudos*                  ${RPM_BUILD_ROOT}/var/lib/cudos/src/v0.9.0/

# Install the newly built binaries
cp -v ${RPM_BUILD_DIR}/go/bin/cudos-noded       ${RPM_BUILD_ROOT}/var/lib/cudos/cudos-data/cosmovisor/upgrades/v%{version}/bin/
cp -v ${RPM_BUILD_DIR}/go/pkg/mod/github.com/'!cosm!wasm'/wasmvm*/api/libwasmvm.so ${RPM_BUILD_ROOT}/var/lib/cudos/cudos-data/cosmovisor/upgrades/v%{version}/lib/
chmod 644                                                                          ${RPM_BUILD_ROOT}/var/lib/cudos/cudos-data/cosmovisor/upgrades/v%{version}/lib/*.so

%clean
# rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,cudos,cudos,-)
/var/lib/cudos/cudos-data/cosmovisor
%doc

%files -n cudos-node-v0.9.0-src
%defattr(-,cudos,cudos,-)
/var/lib/cudos/src/v0.9.0/

%changelog
