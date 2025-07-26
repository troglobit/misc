# Firewalld Multi-Port Router Architecture and Zone Concepts

## Overview

This document illustrates how firewalld zones work on multi-port router devices, showing the relationship between physical interfaces, network zones, and traffic flow.

## Basic Zone Concept

```
                    ┌─────────────────────────────────────┐
                    │           Router/Firewall           │
                    │                                     │
   Internet ────────┤ eth0 [external]                     │
                    │                                     │
   DMZ Switch ──────┤ eth1 [dmz]                          │
                    │                                     │
   LAN Switch ──────┤ eth2 [internal]                     │
                    │                                     │
   Mgmt ────────────┤ eth3 [trusted]                      │
                    │                                     │
                    └─────────────────────────────────────┘

Zone Assignment:
• eth0 → external zone  (untrusted, minimal services)
• eth1 → dmz zone       (limited services, monitored)
• eth2 → internal zone  (trusted LAN, many services)
• eth3 → trusted zone   (full access, management)
```

## Detailed Multi-Zone Router Setup

```
     ┌─────────────┐          ┌───────────────────────────────────────┐
     │  Internet   │          │              Router                   │
     │   Provider  │          │                                       │
     └──────┬──────┘          │  ┌─────────────────────────────────┐  │
            │                 │  │         external zone           │  │
            │ 203.0.113.1/24  │  │  • Default: DROP                │  │
            │                 │  │  • Services: none               │  │
     ┌──────▼──────┐          │  │  • Masquerading: yes            │  │
     │    eth0     │◄─────────┤  │  • Target: default              │  │
     │203.0.113.10 │          │  └─────────────────────────────────┘  │
     └─────────────┘          │                                       │
                              │  ┌─────────────────────────────────┐  │
     ┌─────────────┐          │  │           dmz zone              │  │
     │ Web Servers │          │  │  • Default: REJECT              │  │
     │192.168.100.x│          │  │  • Services: http, https, ssh   │  │
     └──────┬──────┘          │  │  • Rich rules: restrictive      │  │
            │                 │  │  • Target: default              │  │
            │ 192.168.100.0/24│  │                                 │  │
     ┌──────▼──────┐          │  └─────────────────────────────────┘  │
     │    eth1     │◄─────────┤                                       │
     │192.168.100.1│          │                                       │
     └─────────────┘          │                                       │
                              │  ┌─────────────────────────────────┐  │
     ┌─────────────┐          │  │         internal zone           │  │
     │  LAN Users  │          │  │  • Default: ACCEPT              │  │
     │192.168.1.x  │          │  │  • Services: ssh, dns, dhcp     │  │
     └──────┬──────┘          │  │  • Rich rules: permissive       │  │
            │                 │  │  • Target: default              │  │
            │ 192.168.1.0/24  │  │                                 │  │
     ┌──────▼──────┐          │  └─────────────────────────────────┘  │
     │    eth2     │◄─────────┤                                       │
     │ 192.168.1.1 │          │                                       │
     └─────────────┘          │                                       │
                              │  ┌─────────────────────────────────┐  │
     ┌─────────────┐          │  │         trusted zone            │  │
     │ Management  │          │  │  • Default: ACCEPT              │  │
     │ 10.0.0.x    │          │  │  • Services: all                │  │
     └──────┬──────┘          │  │  • Rich rules: none needed      │  │
            │                 │  │  • Target: ACCEPT               │  │
            │ 10.0.0.0/24     │  │                                 │  │
     ┌──────▼──────┐          │  └─────────────────────────────────┘  │
     │    eth3     │◄─────────┤                                       │
     │  10.0.0.1   │          │                                       │
     └─────────────┘          └───────────────────────────────────────┘
```

## Traffic Flow Examples

### 1. Internet User Accessing DMZ Web Server

```
Internet User (203.0.113.50) → DMZ Web Server (192.168.100.10:80)

┌─────────┐      ┌─────────────────────────────────────────┐      ┌─────────┐
│Internet │─────▶│ eth0[external] → eth1[dmz]              │─────▶│   DMZ   │
│  User   │ :80  │                                         │ :80  │ Server  │
└─────────┘      │ Rules Applied:                          │      └─────────┘
                 │ 1. external zone: masquerading          │
                 │ 2. Port forward: 80→192.168.100.10:80   │
                 │ 3. dmz zone: allow service "http"       │
                 └─────────────────────────────────────────┘

Flow: external[DROP by default] → forward rule → dmz[http service allowed]
```

### 2. LAN User Accessing Internet

```
LAN User (192.168.1.100) → Internet (8.8.8.8:53)

┌─────────┐      ┌─────────────────────────────────────────┐      ┌─────────┐
│   LAN   │─────▶│ eth2[internal] → eth0[external]         │─────▶│Internet │
│  User   │ :53  │                                         │ :53  │   DNS   │
└─────────┘      │ Rules Applied:                          │      └─────────┘
                 │ 1. internal zone: ACCEPT by default     │
                 │ 2. Routing decision                     │
                 │ 3. external zone: masquerading          │
                 └─────────────────────────────────────────┘

Flow: internal[ACCEPT] → masquerade → external[outbound allowed]
```

### 3. Management Access to All Zones

```
Management (10.0.0.50) → Any Zone

┌─────────┐      ┌─────────────────────────────────────────┐      ┌─────────┐
│  Mgmt   │─────▶│ eth3[trusted] → any interface           │─────▶│   Any   │
│Station  │      │                                         │      │ Target  │
└─────────┘      │ Rules Applied:                          │      └─────────┘
                 │ 1. trusted zone: ACCEPT target          │
                 │ 2. All services allowed                 │
                 │ 3. No restrictions                      │
                 └─────────────────────────────────────────┘

Flow: trusted[ACCEPT all] → unrestricted access
```

## Zone Configuration Matrix

```
┌──────────┬────────────┬─────────────┬─────────────┬─────────────┐
│   Zone   │  Interface │   Target    │  Services   │   Access    │
├──────────┼────────────┼─────────────┼─────────────┼─────────────┤
│external  │    eth0    │   default   │    none     │ Deny inbound│
│          │            │ (DROP new)  │             │ Allow outbd │
├──────────┼────────────┼─────────────┼─────────────┼─────────────┤
│   dmz    │    eth1    │   default   │ http,https  │ Limited in  │
│          │            │ (REJECT)    │    ssh      │ Allow outbd │
├──────────┼────────────┼─────────────┼─────────────┼─────────────┤
│internal  │    eth2    │   default   │ ssh,dns,    │ Permissive  │
│          │            │ (ACCEPT)    │ dhcp,ntp    │             │
├──────────┼────────────┼─────────────┼─────────────┼─────────────┤
│trusted   │    eth3    │   ACCEPT    │     all     │ Full access │
└──────────┴────────────┴─────────────┴─────────────┴─────────────┘
```

## Rich Rule Examples for Multi-Zone Setup

### DMZ Zone Rich Rules
```
# Allow web access only from external
rich rule: rule family="ipv4" source address="0.0.0.0/0" service name="http" accept

# Allow SSH only from management network
rich rule: rule family="ipv4" source address="10.0.0.0/24" service name="ssh" accept

# Log and block everything else
rich rule: rule family="ipv4" log prefix="DMZ-REJECT" level="warning" reject
```

### Internal Zone Rich Rules
```
# Allow internal to access DMZ web servers
rich rule: rule family="ipv4" destination address="192.168.100.0/24" service name="http" accept

# Block internal users from management network
rich rule: rule family="ipv4" destination address="10.0.0.0/24" reject

# Rate limit SSH attempts
rich rule: rule family="ipv4" service name="ssh" log prefix="SSH-ATTEMPT" level="info" limit value="3/m" accept
```

## VLAN-Based Zone Assignment

```
                    ┌─────────────────────────────────────────┐
                    │              Router                     │
                    │                                         │
                    │  ┌─────────────────────────────────┐    │
   Internet ────────┤  │ eth0 (no VLAN) → external zone  │    │
                    │  └─────────────────────────────────┘    │
                    │                                         │
                    │  eth1 (trunk port):                     │
                    │  ┌─────────────────────────────────┐    │
   Switch ──────────┤  │ eth1.100 (VLAN 100) → dmz       │    │
   (Trunk)          │  │ eth1.200 (VLAN 200) → internal  │    │
                    │  │ eth1.300 (VLAN 300) → guest     │    │
                    │  └─────────────────────────────────┘    │
                    │                                         │
                    │  ┌─────────────────────────────────┐    │
   Management ──────┤  │ eth2 (no VLAN) → trusted zone   │    │
                    │  └─────────────────────────────────┘    │
                    └─────────────────────────────────────────┘

Configuration Commands:
# ip link add link eth1 name eth1.100 type vlan id 100
# ip link add link eth1 name eth1.200 type vlan id 200
# ip link add link eth1 name eth1.300 type vlan id 300

# firewall-cmd --zone=dmz --add-interface=eth1.100 --permanent
# firewall-cmd --zone=internal --add-interface=eth1.200 --permanent
# firewall-cmd --zone=guest --add-interface=eth1.300 --permanent
```

## Source-Based Zone Assignment

```
Physical Topology:
                    ┌─────────────────────────────────────────┐
                    │              Router                     │
   Mixed Network ───┤ eth1 (multiple subnets on same wire)    │
                    └─────────────────────────────────────────┘
                           │
                    ┌─────────────────┐
                    │   Switch        │
                    │                 │
   ┌────────────────┤ 192.168.1.0/24  │ (Office LAN)
   │                │ 192.168.2.0/24  │ (Guest WiFi)
   │                │ 10.0.0.0/24     │ (IoT devices)
   └────────────────┤                 │
                    └─────────────────┘

Zone Assignment by Source:
┌─────────────────┬─────────────────┬─────────────────────────┐
│     Source      │      Zone       │       Treatment         │
├─────────────────┼─────────────────┼─────────────────────────┤
│ 192.168.1.0/24  │    internal     │ Full LAN access         │
│ 192.168.2.0/24  │     guest       │ Internet only           │
│ 10.0.0.0/24     │      iot        │ Limited services        │
│ (unmatched)     │ public (default)│ Restrictive default     │
└─────────────────┴─────────────────┴─────────────────────────┘

Configuration:
# firewall-cmd --zone=internal --add-source=192.168.1.0/24 --permanent
# firewall-cmd --zone=guest --add-source=192.168.2.0/24 --permanent
# firewall-cmd --zone=iot --add-source=10.0.0.0/24 --permanent
# firewall-cmd --set-default-zone=public
```

## Inter-Zone Communication Flow

```
Communication Matrix:

        │ external │   dmz    │ internal │ trusted │
────────┼──────────┼──────────┼──────────┼─────────┤
external│    ✓     │    →     │    ✗     │    ✗    │
  dmz   │    ✓     │    ✓     │    ✗     │    ✗    │
internal│    ✓     │    →     │    ✓     │    ✗    │
trusted │    ✓     │    ✓     │    ✓     │    ✓    │

Legend:
✓ = Full communication allowed
→ = Limited/service-specific communication
✗ = Communication blocked by default

Detailed Rules:
┌─────────────────────────────────────────────────────────────┐
│ external → dmz:    Only to published services (80,443)      │
│ internal → dmz:    Web access + internal management         │
│ trusted → all:     Unrestricted administrative access       │
│ dmz → external:    Outbound for updates, etc.               │
│ internal → external: Full internet access via NAT           │
└─────────────────────────────────────────────────────────────┘
```

## Practical Implementation Commands

### Complete Router Setup Script
```bash
#!/bin/bash

# Set default zone
firewall-cmd --set-default-zone=external

# Configure external zone (WAN)
firewall-cmd --permanent --zone=external --add-interface=eth0
firewall-cmd --permanent --zone=external --add-masquerade
firewall-cmd --permanent --zone=external --add-forward-port=port=80:proto=tcp:toaddr=192.168.100.10
firewall-cmd --permanent --zone=external --add-forward-port=port=443:proto=tcp:toaddr=192.168.100.10

# Configure DMZ zone
firewall-cmd --permanent --zone=dmz --add-interface=eth1
firewall-cmd --permanent --zone=dmz --add-service=http
firewall-cmd --permanent --zone=dmz --add-service=https
firewall-cmd --permanent --zone=dmz --add-rich-rule='rule family="ipv4" source address="10.0.0.0/24" service name="ssh" accept'

# Configure internal zone (LAN)
firewall-cmd --permanent --zone=internal --add-interface=eth2
firewall-cmd --permanent --zone=internal --add-service=ssh
firewall-cmd --permanent --zone=internal --add-service=dns
firewall-cmd --permanent --zone=internal --add-service=dhcp

# Configure trusted zone (Management)
firewall-cmd --permanent --zone=trusted --add-interface=eth3

# Apply configuration
firewall-cmd --reload

# Verify configuration
firewall-cmd --get-active-zones
firewall-cmd --list-all-zones
```

## Troubleshooting Flow Diagrams

### Packet Decision Flow
```
Incoming Packet
       │
       ▼
┌─────────────────┐
│ Which interface?│ ──────────┐
└─────────────────┘           │
       │                      │
       ▼                      ▼
┌─────────────────┐    ┌─────────────────┐
│Interface has    │    │ Use source-based│
│zone assignment? │    │ zone matching   │
└─────────────────┘    └─────────────────┘
       │                      │
       ▼                      │
┌─────────────────┐           │
│ Use interface   │ ◄─────────┘
│ zone            │
└─────────────────┘
       │
       ▼
┌─────────────────┐
│ Apply zone rules│
│ 1. Rich rules   │
│ 2. Services     │
│ 3. Ports        │
│ 4. Zone target  │
└─────────────────┘
       │
       ▼
┌─────────────────┐
│ ACCEPT/REJECT/  │
│ DROP            │
└─────────────────┘
```

This documentation provides visual representations of how firewalld works in multi-port router scenarios, making it easier to understand zone concepts, traffic flow, and practical implementation for documentation and training purposes.
