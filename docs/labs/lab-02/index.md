# lab-02 - connecting Sweden Central workload spoke VNet to the SwedenCentral hub

In this lab, you will learn how to connect spoke Virtual Network to the Auzre VWan hub. Since workload is located in SwedenCentral, we will connect it to the SwedenCentral hub.

## Task #1 - 

Navigato to `rg-vwan-labs-norwayeast-1 -> vwan-norwayeast-1 -> Settings -> Virtual network connections` and click on `+ Add connection` button. 

![navigate-to-hub](../../assets/images/lab-02/navigate-to-hub.png)

Fill in the form with the following values:

![navigate-to-hub](../../assets/images/lab-02/vnet-link1.png)

| Field | Value |
| --- | --- |
| Connection name | vnet-workload-swedencentral-1 |
| Hubs | Select `hub-swedencentral-1` from the list |
| Subscription | Select Subscription where you VWAn is deployed |
| Resource group | Select `rg-vwan-labs-norwayeast-1` |
| Virtual network | Select `vnet-workload-swedencentral-1` |
| Associate Route Table | Select `Default` |

Keep the rest of the values as default and click `Create` button.


## Task #2 - test connectivity to `vm-wl-swedencentral` Virtual Machines


```powershell
# Get vm-wl-swedencentral private IP address 
az vm list-ip-addresses -g rg-vwan-labs-norwayeast-1 -n vm-wl-swedencentral --query  [0].virtualMachine.network.privateIpAddresses[0] -o tsv

# use private IP from the previous command
ssh iac-user@10.9.3.4
```

![navigate-to-hub](../../assets/images/lab-02/ssh-timeout.png)

Still no connection. Check Azure VPN client VPN Routes at `Connection Properties` page. As you can see there is no route to `10.9.3.0/26` IP range. This is because Azure VPN client haven't received newly linked VNet route from the hub yet. Disconnect and Connect your VPN client and check VPN routes again. Now you should see `10.9.3.0/26` route in the list.

![navigate-to-hub](../../assets/images/lab-02/vpn-routes1.png)
	
Try to SSH to `vm-wl-swedencentral` using `iac-user` / `fooBar123!` again.

```powershell
# ssh to vm-wl-swedencentral
ssh iac-user@10.9.3.4
```

You should now be able to SSH into `vm-dc-swedencentral`.