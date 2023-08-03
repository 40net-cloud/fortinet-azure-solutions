FortiGates VM require to have outbound connectivity to the internet. The frontend IPs of a public load balancer we use in AP or AA HA templates can be used to provide outbound connectivity to the internet for backend FortiGate instances. This configuration uses source network address translation (SNAT) to translate virtual machine's private IP into the load balancer's public IP address. SNAT maps the IP address of the backend to the public IP address of your load balancer.


If using SNAT without outbound rules via a public load balancer, SNAT ports are pre-allocated as described in the following default SNAT ports allocation table:

The following table shows the SNAT port preallocations for backend pool sizes:

![Default port allocation table](images/faq-snat-table.png)