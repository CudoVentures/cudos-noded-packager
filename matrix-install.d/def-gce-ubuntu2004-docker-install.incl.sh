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

gce-ubuntu2004-docker-install()
{
	set -x
	
	export CUDOS_NETWORK="$1"
	export NODE_TYPE="$2"

    echo -ne "\n=== Prepare the platform ===\n\n"

	sudo apt remove unattended-upgrades -y
	echo 'deb [trusted=yes] http://jenkins.gcp.service.cudo.org/cudos/0.9.0/debian stable main' | sudo tee /etc/apt/sources.list.d/cudos.list > /dev/null
    sudo apt update

    echo -ne "\n\n     Install a $NODE_TYPE on $CUDOS_NETWORK\n\n"

	#
	# Select repository and install the packages based on CUDOS_NETWORK
	#
	case $CUDOS_NETWORK in
		mainnet)
			YUMREPO=cudos-1.0.0
			PACKLIST="cudos-network-mainnet cosmovisor cudos-gex cudos-noded cudos-noded-v1.0.0 cudos-noded-v1.1.0 cudos-p2p-scan"
			;;
		public-testnet)
			YUMREPO=cudos-0.9.0
			PACKLIST="cudos-network-public-testnet cosmovisor cudos-gex cudos-noded cudos-noded-v0.9.0 cudos-noded-v1.0.0 cudos-noded-v1.1.0 cudos-p2p-scan"
			;;
		private-testnet)
			YUMREPO=cudos-0.8.0
			PACKLIST="cudos-network-private-testnet cosmovisor cudos-gex cudos-noded cudos-noded-v0.8.0 cudos-noded-v0.9.0 cudos-noded-v1.0.0 cudos-noded-v1.1.0 cudos-p2p-scan"
			;;
	esac
	
	#
	# Install the packages
	#
	if ! sudo apt install -y ${PACKLIST}
	then
		echo -ne "\nError: apt install failed\n\n"
		exit 1
	fi
			
	#
	# Set the CUDOS_HOME variable using the profile
	# just installed through the cudos-noded package
	#
	source /etc/profile.d/cudos-noded.sh

	#
	# Initialise the node using the node type
	#
	if ! sudo -u cudos CUDOS_HOME="${CUDOS_HOME}" /usr/bin/cudos-init-node.sh $NODE_TYPE
	then
		echo -ne "\nError: cudos-init-node.sh returned an error\n\n"
		exit 1
	fi
	
	#
	# Enable and start the cudos-noded service
	#
	if ! sudo systemctl enable --now cosmovisor@cudos
	then
		echo -ne "\nError: Service enable failed\n\n"
		exit 1
	fi
		

	#
	# Hang around a bit to let some logs build up
	#
	echo -ne "Sleeping for 120 seconds\n"
	sleep 120

	#
	# Dump the log since boot for cudos-noded both to the screen
	# for the CI/CD job log, and to a logfile for export as an
	# artifact
	#
	sudo journalctl -b -u cosmovisor@cudos | tee log-${CUDOS_NETWORK}_-_${NODE_TYPE}.txt
	
}

