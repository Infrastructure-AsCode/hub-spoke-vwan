# lab-07 - cleaning up resources

This is the most important part of the workshop. We need to clean up all resources that we provisioned during the workshop to avoid unexpected bills.

## Task #1 - delete lab infrastructure

Remove all resources that were created during the workshop by running the following command:

```powershell
az group delete --name rg-vwan-labs-norwayeast-1 --yes
```

