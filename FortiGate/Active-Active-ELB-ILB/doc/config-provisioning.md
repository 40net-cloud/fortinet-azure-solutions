# Deployment configuration

After deployment, the below configuration has been automatically injected during the deployment. The bold sections are the default values. If parameters have been changed during deployment these values will be different.

## FortiGate A

```text
config system sdn-connector
  edit AzureSDN
    set type azure
  next
end
config router static
  edit 1
    set gateway **172.16.136.1**
    set device port1
  next
  edit 2
    set dst **172.16.136.0/22**
    set device port2
    set gateway **172.16.136.65**
  next
  edit 3
    set dst 168.63.129.16 255.255.255.255
    set device port2
    set gateway **172.16.136.65**
  next
  edit 4
    set dst 168.63.129.16 255.255.255.255
    set device port1
    set gateway **172.16.136.1**
  next
end
config system probe-response
  set http-probe-value OK
  set mode http-probe
end
config system interface
  edit port1
    set mode static
    set ip **172.16.136.5/26**
    set description external
    set allowaccess ping ssh https probe-response
  next
  edit port2
    set mode static
    set ip **172.16.136.69/24**
    set description internal
    set allowaccess ping ssh https probe-response
  next
end
```

## FortiGate B

```text
config system sdn-connector
  edit AzureSDN
    set type azure
  next
end
config router static
  edit 1
    set gateway **172.16.136.1**
    set device port1
  next
  edit 2
    set dst **172.16.136.0/22**
    set device port2
    set gateway **172.16.136.65**
  next
  edit 3
    set dst 168.63.129.16 255.255.255.255
    set device port2
    set gateway **172.16.136.65**
  next
  edit 4
    set dst 168.63.129.16 255.255.255.255
    set device port1
    set gateway **172.16.136.1**
  next
end
config system probe-response
  set http-probe-value OK
  set mode http-probe
end
config system interface
  edit port1
    set mode static
    set ip **172.16.136.6/26**
    set description external
    set allowaccess ping ssh https probe-response
  next
  edit port2
    set mode static
    set ip **172.16.136.70/26**
    set description internal
    set allowaccess ping ssh https probe-response
  next
end
```