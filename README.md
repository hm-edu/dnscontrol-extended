# DNSControl Extended

This project extends dnscontrol by some functionality required at the Munich University of Applied Sciences.

## Free IP List

Figuring out, which IP is free or not can be a cumberstone task. To simplify this, we maintain our (un)used IPs in a GitLab Issue. The subcommand `run` generates the list. Therefore a reverse zone is parsed and utilized.

## Reverse Zone Generator

While hosting our private domain zone, reverse IP records are required to simplify debugging and analysis. The subcommand `gen` performs AXFR requests, generates the reverse zone and saves/updates the zone files.

## GitLab Issue Generator

Beside the CLI functionalities to generate a reverse zone or to identify free IP addresses this tool also provides a command to generate GitLab Issues. These issues contain the free IP ranges of given subnets. In case of large subnets it is also possible to generate seperate issues for several subnets and to ignore empty subnets. 