# lab-01 - configure Azure VPN client

Let's start with configuring Azure VPN client to connect to our Azure lab environment. All further labs will require VPN connection to Azure environment.

Check that Azure VPN client is installed on your machine. If not, download and install it from [here](https://www.microsoft.com/en-us/p/azure-vpn-client/9np355qt2sqb?activetab=pivot:overviewtab), or use `winget` (only for Windows users):

```powershell
winget install "azure vpn client"
```

Next, from Azure portal, download client profile configuration file. Go to your Virtual network gateway resource `iac-ws5-vgw` and click on `Download VPN client` file.


Extract `.zip` archive. It contains two folder:

![vpn-config](../../assets/images/lab-01/vpn-client-config-folders.png)

Start Azure Vpn client and import `azurevpnconfig.xml` file from `AzureVPN` folder. It will create new VPN connection profile. 

![import-vpn-config](../../assets/images/lab-01/import-vpn-config.png)

When `azurevpnconfig.xml` file is loaded, click `Save`.

![import-vpn-config](../../assets/images/lab-01/import-vpn-config-1.png)

You will now see new VPN connection profile in Azure VPN client and you can connect to it.

![connect](../../assets/images/lab-01/vpn-connect.png)

You will be asked to enter your Azure AD credentials and if everything is configured correctly, you will be connected to your Azure lab environment. Note, you will only need to provide your Azure AD credentials when you connect to VPN for the first time. Next time you will be connected automatically.

![connected](../../assets/images/lab-01/vpn-connected.png)

Under the `Connected properties` you can find what is your VPN IP Address and what VPN routes are available. As you can see, our `iac-ws5-vnet` address range (`10.10.0.0/22`) is accessible. You can find the same VPN IP Address if you run `ipconfig` command in your terminal.
