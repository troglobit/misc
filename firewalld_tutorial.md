# Firewalld Command Reference and XML Configuration Tutorial

## Overview

This tutorial covers firewalld command-line usage and XML configuration structure, designed for developers working with YANG models and automated configuration generation.

## Basic Status and Information

### Service Status
```bash
# Check if firewalld is running
firewall-cmd --state

# Get firewalld version
firewall-cmd --version

# Reload configuration (apply permanent changes)
firewall-cmd --reload

# Get help
firewall-cmd --help
```

### Zone Information
```bash
# Get current active zones and interfaces
firewall-cmd --get-active-zones

# List all available zones
firewall-cmd --get-zones

# Get default zone
firewall-cmd --get-default-zone

# List all zones with full details
firewall-cmd --list-all-zones

# Get specific zone configuration
firewall-cmd --zone=public --list-all
```

### Service Information
```bash
# List all available services
firewall-cmd --get-services

# Get service details
firewall-cmd --info-service=ssh

# List all available ICMP types
firewall-cmd --get-icmptypes
```

## Zone Management

### Basic Zone Operations
```bash
# Create a new zone
firewall-cmd --permanent --new-zone=myzone
firewall-cmd --reload

# Delete a zone
firewall-cmd --permanent --delete-zone=myzone
firewall-cmd --reload

# Set default zone
firewall-cmd --set-default-zone=internal

# Change zone for interface
firewall-cmd --zone=internal --change-interface=eth1
```

### Zone Configuration
```bash
# Set zone description
firewall-cmd --permanent --zone=myzone --set-description="My Custom Zone"

# Set zone short name
firewall-cmd --permanent --zone=myzone --set-short="MyZone"

# Set zone target (default behavior for unmatched traffic)
firewall-cmd --permanent --zone=myzone --set-target=ACCEPT
# Targets: default, ACCEPT, REJECT, DROP
```

## Service and Port Management

### Services
```bash
# Add a service to a zone (runtime only)
firewall-cmd --zone=public --add-service=ssh

# Add a service permanently
firewall-cmd --zone=public --add-service=ssh --permanent

# Remove a service
firewall-cmd --zone=public --remove-service=ssh
firewall-cmd --zone=public --remove-service=ssh --permanent

# List services in a zone
firewall-cmd --zone=public --list-services

# Check if service is enabled
firewall-cmd --zone=public --query-service=ssh
```

### Ports
```bash
# Add custom port (TCP)
firewall-cmd --zone=public --add-port=8080/tcp
firewall-cmd --zone=public --add-port=8080/tcp --permanent

# Add UDP port
firewall-cmd --zone=public --add-port=53/udp --permanent

# Add port range
firewall-cmd --zone=public --add-port=5000-5010/tcp --permanent

# Remove port
firewall-cmd --zone=public --remove-port=8080/tcp --permanent

# List ports in zone
firewall-cmd --zone=public --list-ports

# Query if port is open
firewall-cmd --zone=public --query-port=8080/tcp
```

## Interface and Source Management

### Interface Assignment
```bash
# Assign interface to zone
firewall-cmd --zone=internal --add-interface=eth1
firewall-cmd --zone=internal --add-interface=eth1 --permanent

# Remove interface from zone
firewall-cmd --zone=internal --remove-interface=eth1 --permanent

# List interfaces in zone
firewall-cmd --zone=internal --list-interfaces

# Change interface zone
firewall-cmd --zone=dmz --change-interface=eth1
```

### Source-based Rules
```bash
# Add source network to zone
firewall-cmd --zone=internal --add-source=192.168.1.0/24
firewall-cmd --zone=internal --add-source=192.168.1.0/24 --permanent

# Add specific IP
firewall-cmd --zone=trusted --add-source=10.0.0.100 --permanent

# Remove source
firewall-cmd --zone=internal --remove-source=192.168.1.0/24 --permanent

# List sources
firewall-cmd --zone=internal --list-sources
```

## Advanced Features

### Rich Rules
Rich rules provide fine-grained control over traffic:

```bash
# Allow SSH from specific network
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept'

# Block specific IP
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.100" reject'

# Allow port with logging
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" port protocol="tcp" port="8080" log prefix="HTTP-8080" level="info" accept'

# Rate limiting
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" service name="ssh" log prefix="SSH" level="info" limit value="3/m" accept'

# Time-based rule (requires --permanent)
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" service name="ftp" audit limit value="1/m" accept'

# List rich rules
firewall-cmd --zone=public --list-rich-rules
```

### Port Forwarding
```bash
# Forward external port to internal port
firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080

# Forward to different host
firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toaddr=192.168.1.100:toport=80

# List port forwards
firewall-cmd --zone=public --list-forward-ports
```

### Masquerading (NAT)
```bash
# Enable masquerading (NAT)
firewall-cmd --zone=public --add-masquerade
firewall-cmd --zone=public --add-masquerade --permanent

# Check masquerading status
firewall-cmd --zone=public --query-masquerade

# List zones with masquerading
firewall-cmd --get-zones | xargs -I {} sh -c 'echo -n "{}: "; firewall-cmd --zone={} --query-masquerade 2>/dev/null && echo "enabled" || echo "disabled"'
```

### ICMP Filtering
```bash
# Block specific ICMP types
firewall-cmd --zone=public --add-icmp-block=echo-reply
firewall-cmd --zone=public --add-icmp-block=echo-request --permanent

# List blocked ICMP types
firewall-cmd --zone=public --list-icmp-blocks

# Block all ICMP except specific types
firewall-cmd --zone=public --add-icmp-block-inversion --permanent
```

## Custom Services

### Creating Custom Services
```bash
# Create a custom service definition
firewall-cmd --permanent --new-service=myapp

# Set service details
firewall-cmd --permanent --service=myapp --set-description="My Application"
firewall-cmd --permanent --service=myapp --set-short="MyApp"
firewall-cmd --permanent --service=myapp --add-port=9000/tcp
firewall-cmd --permanent --service=myapp --add-port=9001/udp

# Apply changes
firewall-cmd --reload

# Use the custom service
firewall-cmd --zone=public --add-service=myapp --permanent
```

## Configuration Files and XML Structure

### File Locations
```bash
# User/custom configurations (takes precedence)
ls -la /etc/firewalld/zones/
ls -la /etc/firewalld/services/
ls -la /etc/firewalld/icmptypes/

# System defaults (fallback)
ls -la /usr/lib/firewalld/zones/
ls -la /usr/lib/firewalld/services/
ls -la /usr/lib/firewalld/icmptypes/

# Main configuration
cat /etc/firewalld/firewalld.conf
```

### Zone XML Structure

#### Basic Zone Example (`/etc/firewalld/zones/public.xml`)
```xml
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>Public</short>
  <description>For use in public areas. You do not trust the other computers on networks to not harm your computer. Only selected incoming connections are accepted.</description>
  <service name="ssh"/>
  <service name="dhcpv6-client"/>
  <port protocol="tcp" port="8080"/>
  <interface name="eth0"/>
</zone>
```

#### Complex Zone Example
```xml
<?xml version="1.0" encoding="utf-8"?>
<zone target="default">
  <short>DMZ</short>
  <description>For computers in your demilitarized zone that are publicly-accessible with limited access to your internal network. Only selected incoming connections are accepted.</description>
  
  <!-- Services -->
  <service name="ssh"/>
  <service name="http"/>
  <service name="https"/>
  
  <!-- Custom ports -->
  <port port="8443" protocol="tcp"/>
  <port port="10000-10010" protocol="udp"/>
  
  <!-- Source networks -->
  <source address="192.168.1.0/24"/>
  <source address="10.0.0.0/8"/>
  
  <!-- Interfaces -->
  <interface name="eth1"/>
  <interface name="eth2"/>
  
  <!-- Port forwarding -->
  <forward-port port="80" protocol="tcp" to-port="8080"/>
  <forward-port port="443" protocol="tcp" to-addr="192.168.1.100" to-port="443"/>
  
  <!-- Enable masquerading -->
  <masquerade/>
  
  <!-- ICMP blocks -->
  <icmp-block name="echo-request"/>
  <icmp-block name="echo-reply"/>
  
  <!-- Rich rules -->
  <rule family="ipv4">
    <source address="192.168.1.0/24"/>
    <service name="ftp"/>
    <log prefix="FTP-ACCESS" level="info">
      <limit value="1/m"/>
    </log>
    <accept/>
  </rule>
  
  <rule family="ipv4">
    <source address="192.168.100.0/24"/>
    <port port="3389" protocol="tcp"/>
    <reject type="icmp-port-unreachable"/>
  </rule>
</zone>
```

### Service XML Structure

#### Basic Service Example (`/etc/firewalld/services/myapp.xml`)
```xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>MyApp</short>
  <description>My custom application service</description>
  <port protocol="tcp" port="9000"/>
  <port protocol="udp" port="9001"/>
  <port protocol="tcp" port="9100-9110"/>
</service>
```

#### Complex Service Example
```xml
<?xml version="1.0" encoding="utf-8"?>
<service version="1.0">
  <short>Complex Service</short>
  <description>A complex service with multiple requirements</description>
  
  <!-- Multiple ports -->
  <port port="80" protocol="tcp"/>
  <port port="443" protocol="tcp"/>
  <port port="8080-8090" protocol="tcp"/>
  <port port="53" protocol="udp"/>
  
  <!-- Modules to load -->
  <module name="nf_conntrack_ftp"/>
  <module name="nf_nat_ftp"/>
  
  <!-- Destination addresses/ports -->
  <destination ipv4="224.0.0.1" ipv6="ff02::1"/>
  
  <!-- Include other services -->
  <include service="ssh"/>
</service>
```

### ICMP Type XML Structure
```xml
<?xml version="1.0" encoding="utf-8"?>
<icmptype>
  <short>Custom ICMP</short>
  <description>Custom ICMP type definition</description>
  <destination ipv4="yes" ipv6="yes"/>
</icmptype>
```

## Debugging and Inspection

### Logging Configuration
```bash
# Enable logging for denied packets
firewall-cmd --set-log-denied=all
# Options: all, unicast, broadcast, multicast, off

# Set log level
firewall-cmd --get-log-denied

# Check logs (varies by system)
journalctl -u firewalld
tail -f /var/log/messages | grep kernel
```

### Direct Interface (Low-level iptables)
```bash
# View all direct rules
firewall-cmd --direct --get-all-rules

# Add direct iptables rule
firewall-cmd --direct --add-rule ipv4 filter INPUT 0 -p tcp --dport 12345 -j ACCEPT

# List direct chains
firewall-cmd --direct --get-all-chains
```

### Runtime vs Permanent Configuration
```bash
# Show runtime configuration
firewall-cmd --list-all

# Show permanent configuration
firewall-cmd --permanent --list-all

# Compare runtime vs permanent
diff <(firewall-cmd --list-all-zones) <(firewall-cmd --permanent --list-all-zones)
```

## Useful Inspection Commands

### Configuration Analysis
```bash
# Check what changed from defaults
firewall-cmd --list-all-zones | grep -E "(services:|ports:|interfaces:|sources:)"

# Find which zone an interface belongs to
firewall-cmd --get-zone-of-interface=eth0

# Find which zone a source belongs to
firewall-cmd --get-zone-of-source=192.168.1.100

# List all active configurations
firewall-cmd --get-active-zones | while read zone; do
  echo "=== $zone ==="
  firewall-cmd --zone="$zone" --list-all
done
```

### XML Validation
```bash
# Validate XML syntax
xmllint --noout /etc/firewalld/zones/public.xml

# Pretty print XML
xmllint --format /etc/firewalld/zones/public.xml

# Check XML against schema (if available)
xmllint --schema /usr/share/firewalld/xmlschema/zone.xsd /etc/firewalld/zones/public.xml
```

## Integration Notes for YANG Models

When designing your YANG model for firewalld integration:

1. **Zone Hierarchy**: Zones are the primary organizational unit
2. **Target Behavior**: Each zone has a default target (ACCEPT, REJECT, DROP, default)
3. **Precedence**: Rich rules have higher precedence than simple service/port rules
4. **Interface Binding**: Interfaces can only belong to one zone at a time
5. **Source vs Interface**: Traffic is matched by source first, then interface
6. **Permanent vs Runtime**: Always consider both runtime and permanent configuration states

## Common Patterns for Automation

### Backup and Restore
```bash
# Backup current configuration
cp -r /etc/firewalld/ /backup/firewalld-$(date +%Y%m%d)

# Generate configuration dump
firewall-cmd --list-all-zones > firewall-config-dump.txt
```

### Atomic Updates
```bash
# Make multiple permanent changes
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" accept'

# Apply all changes atomically
firewall-cmd --reload
```

This tutorial provides a comprehensive foundation for understanding firewalld's command-line interface and XML structure, essential for implementing a complete YANG-based configuration system.