# DNSControl Extended

This project extends dnscontrol by some functionality required at the Munich University of Applied Sciences.

## Free IP List

Figuring out, which IP is free or not can be a cumberstone task. To simplify this, we maintain our (un)used IPs in a GitLab Issue. The subcommand `run` generates the list. Therefore a reverse zone is parsed and utilized.

## Reverse Zone Generator

While hosting our private domain zone, reverse IP records are required to simplify debugging and analysis. The subcommand `gen` performs AXFR requests, generates the reverse zone and saves/updates the zone files.
