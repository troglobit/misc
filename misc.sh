#!/bin/sh
set -x

echo "Creating world ..."
ip link add br0 type bridge vlan_filtering 1 mcast_snooping 0
ip link add a1 type veth peer b1
ip link add a2 type veth peer b2
ip link set b1 master br0
ip link set b2 master br0

ip link set a1 up
ip link set b1 up
ip link set a2 up
ip link set b2 up
ip link set br0 up

ip link add link br0 vlan1 type vlan id 1
ip link add link br0 vlan2 type vlan id 2

ip link set vlan1 up
ip link set vlan2 up

# Move b2 to VLAN 2
bridge vlan add vid 2 dev b2 pvid untagged
bridge vlan del vid 1 dev b2

# Set br0 as tagged member of both VLANs
bridge vlan add vid 1 dev br0 self
bridge vlan add vid 2 dev br0 self

ip -br link

echo "IP world ..."
ip addr add fdd1:9ac8:e35b:4e2d::1/64 dev vlan1
ip addr add 2001:db8::214:51ff:fe2f:1556/64 dev vlan2

ip -br addr
