# DNS-HealthCheck

This contains a small collection of scripts designed to help check the health of an on-premises DNS server.
To use, change the variables $DNSServerName to the FQDN of your DNS server, and the output path to whatever directory you want the output to.

The script TestDNSRecords will ping all static A-records in your DNS, and export the results of the pings to a CSV file.
This is intended to find outdated records in the DNS.

The script FindDNSDuplicates will go through all A and PTR records in the DNS, and export a list of all duplicates found (i.e IP adresses or hostnames appearing twice or more)
This is both to help find old static records of replaced machines which have mistakenly been left, as well as identify any problems with duplicates, for example two or more clients being designated the same IP address.

Feel free to use, copy or take inspiration from the scripts in any way you'd like.
