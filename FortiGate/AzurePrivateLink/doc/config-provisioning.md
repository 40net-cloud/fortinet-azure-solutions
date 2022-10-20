
# Deployment configuration

After deployment, the below configuration has been automatically injected during the deployment. The bold sections are the default values. If parameters have been changed during deployment these values will be different.

## FortiGate A

<pre><code>
config system sdn-connector
  edit AzureSDN
    set type azure
  next
end
config router static
  edit 1
    set gateway <b>172.16.136.1</b>
    set device port1
  next
  edit 2
    set dst <b>172.16.136.0/22</b>
    set device port2
    set gateway <b>172.16.137.1</b>
  next
end
config system interface
  edit port1
    set mode static
    set ip <b>172.16.136.4/24</b>
    set description external
    set allowaccess ping ssh https
  next
  edit port2
    set mode static
    set ip <b>172.16.137.4/24</b>
    set description internal
    set allowaccess ping ssh https
  next
end
</code></pre>

You need to add firewall policy to allow traffic flow between client and endpoint. You can also specify the source as your clients subnet and the destination as private endpoint subnet.

<pre><code>
config firewall policy
    edit 1
        set name "traffic_client_endpoint"
        set uuid f55ecfa4-35b8-51ed-c699-dc4b27ae5f57
        set srcintf "port2"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "ALL"
        set logtraffic all
        set logtraffic-start enable

</code></pre>
