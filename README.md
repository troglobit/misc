# misc
Misc. tests github/markdown/code all in the public domain


```.dot
graph "my-network" {
        node [shape=record];
        qn_template="netbox-os-zero";
		qn_append="quiet";

        server [label="server | { <eth0> eth0 | <eth1> eth1 }"];
        client1 [label="client1 | { <eth0> eth0 }"];
        client2 [label="client2 | { <eth0> eth0 }"];

        server:eth0 -- client1:eth0;
        server:eth1 -- client2:eth0;
}
```
