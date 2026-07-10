#!/bin/sh

# MPTCP bonding setup script
# This script configures MPTCP bonding for multiple WAN interfaces

[ -f /etc/config/mptcp-bonding ] || exit 1

# Load UCI configuration
. /lib/functions.sh
config_load mptcp-bonding

# Get global settings
local enabled convergence_server convergence_port
config_get_bool enabled 'global' 'enabled' '0'
config_get convergence_server 'global' 'convergence_server' '192.168.1.100'
config_get convergence_port 'global' 'convergence_port' '9001'
config_get convergence_password 'global' 'convergence_password' ''

[ "$enabled" = "1" ] || exit 0

# Health check function
health_check() {
	local interface=$1
	local server=$2
	local port=$3
	
	ping -c 1 -W 1 $server >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		logger "MPTCP bonding: $interface health check passed"
		return 0
	else
		logger "MPTCP bonding: $interface health check failed"
		return 1
	fi
}

# Setup MPTCP routes
setup_routes() {
	local cfg="$1"
	local enabled interface weight backup
	
	config_get_bool enabled "$cfg" 'enabled' '0'
	[ "$enabled" = "1" ] || return 0
	
	config_get interface "$cfg" 'interface'
	[ -n "$interface" ] || return 0
	
	# Add default route for this interface with appropriate metric
	local metric=$((100 + $(echo $interface | tail -c 2)))
	ip route add default via $(ip -4 addr show $interface | grep -oP '(?<=inet )\d+(\.\d+){3}') dev $interface metric $metric 2>/dev/null || true
	
	logger "MPTCP bonding: added route for $interface with metric $metric"
}

# Monitor interfaces and perform failover
monitor_interfaces() {
	while true; do
		config_foreach check_interface 'interface'
		sleep 30
	done
}

check_interface() {
	local cfg="$1"
	local enabled interface backup
	
	config_get_bool enabled "$cfg" 'enabled' '0'
	[ "$enabled" = "1" ] || return 0
	
	config_get interface "$cfg" 'interface'
	config_get backup "$cfg" 'backup' '0'
	
	[ -n "$interface" ] || return 0
	
	# Skip backup interfaces for health checks
	[ "$backup" = "1" ] && return 0
	
	health_check "$interface" "$convergence_server" "$convergence_port"
	
	if [ $? -ne 0 ]; then
		logger "MPTCP bonding: interface $interface failed, triggering failover"
		# Here you could add failover logic to enable backup interfaces
	fi
}

# Main setup
setup_routes 'interface'

# Start monitoring in background
if [ "$1" != "no-monitor" ]; then
	monitor_interfaces &
fi

logger "MPTCP bonding: setup completed"