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

Version:      %{_versiontag}
Name:         osmosisd-v15.2.0
Release:      %{_releasetag}%{?dist}
Summary:      Osmosis Node Binary Pack for v15.2.0

License:      GPL3
URL:          https://github.com/osmosis-labs/osmosis

Provides:     libwasmvm.x86_64.so()(64bit)
Requires:     osmosisd

Obsoletes:    osmosisd-v15.0.0

%description
Osmosis Node binary and library

Installed into the Cosmovisor directories

%pre
getent group osmosis >/dev/null || echo "  Create Group osmosis" || groupadd -r osmosis || :
getent passwd osmosis >/dev/null || echo "  Create User osmosis"  useradd -c "Osmosis User" -g osmosis -s /bin/bash -r -m -d /var/lib/osmosis osmosis 2> /dev/null || :

%prep
echo -e "\n\n=== prep section ===\n\n"

%build
echo -e "\n\n=== build section ===\n\n"
export GOPATH="${RPM_BUILD_DIR}/go"

rm -rf osmosis
git clone https://github.com/osmosis-labs/osmosis
cd osmosis
git checkout v15.2.0
echo -e "\n\n***** Build Osmosis Daemon *****\n\n"
make build
echo -e "\n\n***** Run Osmosis Daemon Self Test *****\n\n"
make test || true

%install
echo -e "\n\n=== install section ===\n\n"

# Make the fixed directory structure
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v15/bin
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v15/lib/

# Install the newly built binaries
cp -v ${RPM_BUILD_DIR}/osmosis/build/osmosisd                                                             ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v15/bin/
cp -v ${RPM_BUILD_DIR}'/go/pkg/mod/github.com/!cosm!wasm/wasmvm@v1.1.2/internal/api/libwasmvm.x86_64.so'  ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v15/lib/
chmod 644  ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v15/lib/*

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,osmosis,osmosis,-)
/var/lib/osmosis/.osmosisd/cosmovisor/*
%doc

%changelog
