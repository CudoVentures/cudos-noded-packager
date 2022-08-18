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
# Runs the Osmosis Node Daemon
#

Name:         cosmovisor
Version:      1.0.0
Release:      %{_releasetag}%{?dist}
Summary:      Osmosis Node Common Files

License:      GPL3
URL:          https://github.com/cosmos/cosmos-sdk/cosmovisor

Source1:      cosmovisor@.service
Source4:      cosmovisor-init-node.sh

# undefine __brp_mangle_shebangs
# %global __brp_check_rpaths %{nil}

%description
Cosmos Cosmovisor

%build
echo -e "\n\n=== Build and install cosmovisor ===\n\n"
export GOPATH="${RPM_BUILD_DIR}/go"
go install -v github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0

%install
echo -e "\n\n=== install section ===\n\n"

# Make the fixed directory structure
mkdir -p ${RPM_BUILD_ROOT}/usr/bin
mkdir -p ${RPM_BUILD_ROOT}/usr/lib/systemd/system

# Install the newly built binaries
cp -v ${RPM_BUILD_DIR}/go/bin/cosmovisor        ${RPM_BUILD_ROOT}/usr/bin/

# Install scripts
cp -v ${RPM_SOURCE_DIR}/cosmovisor-init-node.sh      ${RPM_BUILD_ROOT}/usr/bin/
chmod 755                                       ${RPM_BUILD_ROOT}/usr/bin/*.sh

# Install systemd service files
cp ${RPM_SOURCE_DIR}/cosmovisor@.service                         ${RPM_BUILD_ROOT}/usr/lib/systemd/system/

%files
%defattr(-,root,root,-)
/usr/bin/cosmovisor
/usr/bin/cosmovisor-init-node.sh
/usr/lib/systemd/system/cosmovisor@.service
%doc

%changelog