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
# Contains the Network definition files for the Osmosis Testnet network
#

Name:         osmosis-network-testnet
Version:      %{_versiontag}
Release:      %{_releasetag}%{?dist}
Summary:      osmosis Testnet Network Definition Files

License:      GPL3
URL:          https://github.com/osmosis-labs/osmosis

Source0:      osmosis-network-testnet_config.tar.gz

Requires:     cosmovisor
Requires:     osmosisd
Requires:     osmosisd-v11.0.0
Requires:     osmosisd-v12.3.0
Requires:     osmosisd-v13.0.0-rc5
Requires:     osmosisd-v14.0.0
Requires:     osmosisd-v15.0.0
Requires:     osmosisd-v15.2.0
Requires:     osmosisd-v16.1.0
Requires:     osmosisd-v16.1.2
Requires:     osmosisd-v17.0.0
Requires:     osmosisd-v18.0.0
Requires:     osmosisd-v19.0.0
Requires:     osmosisd-v19.2.0
Requires:     cudos-p2p-scan
Requires:     cudos-gex

%description
Osmosis Testnet Network Definition Files

%prep
echo -e "\n\n=== prep section ===\n\n"
tar -C ${RPM_SOURCE_DIR} -xzf ${RPM_SOURCE_DIR}/osmosis-network-testnet_config.tar.gz

%build

%install
echo -e "\n\n=== install section ===\n\n"

# Make the fixed directory structure
mkdir -p ${RPM_BUILD_ROOT}/etc/default
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/config
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v11
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v12
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v13_testnet_rc5
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v14
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v15
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v16
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v17
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v18
mkdir -p ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v19


# Install the .osmosisd/config files
cp -v ${RPM_SOURCE_DIR}/genesis.json                   ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/config/
cp -v ${RPM_SOURCE_DIR}/persistent-peers.config        ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/config/
cp -v ${RPM_SOURCE_DIR}/seeds.config                   ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/config/
cp -v ${RPM_SOURCE_DIR}/state-sync-rpc-servers.config  ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/config/
cp -v ${RPM_SOURCE_DIR}/unconditional-peers.config     ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/config/
cp -v ${RPM_SOURCE_DIR}/private-peers.config           ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/config/

# Create genesis link to the chains genesis version
ln -s /var/lib/osmosis/.osmosisd/cosmovisor/upgrades/v11 ${RPM_BUILD_ROOT}/var/lib/osmosis/.osmosisd/cosmovisor/genesis

# Create /etc/default link for cosmovisor
ln -s cosmovisor@osmosis ${RPM_BUILD_ROOT}/etc/default/cosmovisor 

%clean
rm -rf $RPM_BUILD_ROOT

%pre
getent group osmosis >/dev/null || groupadd -r osmosis || :
getent passwd osmosis >/dev/null || useradd -c "Osmosis User" -g osmosis -s /bin/bash -r -m -d /var/lib/osmosis osmosis 2> /dev/null || :

%files
%attr(-, root, root) %config(noreplace) /etc/default/cosmovisor
%defattr(-,osmosis,osmosis,-)
%dir /var/lib/osmosis/.osmosisd
%dir /var/lib/osmosis/.osmosisd/config
%config(noreplace) /var/lib/osmosis/.osmosisd/config/genesis.json
%config(noreplace) /var/lib/osmosis/.osmosisd/config/persistent-peers.config
%config(noreplace) /var/lib/osmosis/.osmosisd/config/seeds.config
%config(noreplace) /var/lib/osmosis/.osmosisd/config/state-sync-rpc-servers.config
%config(noreplace) /var/lib/osmosis/.osmosisd/config/unconditional-peers.config
%config(noreplace) /var/lib/osmosis/.osmosisd/config/private-peers.config
/var/lib/osmosis/.osmosisd/cosmovisor

%doc
