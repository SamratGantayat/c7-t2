cd C:\Users\PSDemo\Desktop\Demos\aks-monitoring\m03
# Scale nginx Deployment
kubectl scale deployment nginx --replicas=350 -n nginx

# Check out status
kubectl get deployment nginx -n nginx
kubectl get pods -n nginx --field-selector=status.phase!=Running
kubectl describe pod -n nginx (kubectl get pods -n nginx -o=jsonpath='{.items[0].metadata.name}' --field-selector=status.phase!=Running)

# Delete nginx
kubectl delete namespace nginx

# Create Namespace
kubectl create namespace azurefilekeys
kubectl config set-context --current --namespace azurefilekeys

# Create a storage account and share
$azFileStorage="azfile"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
az storage account create -n $azFileStorage -g $RG -l $Region --sku Standard_LRS
$StorageConnString=(az storage account show-connection-string -n $azFileStorage -g $RG -o tsv)
az storage share create -n aksshare --connection-string $StorageConnString

# Get the storage key and store it as a secret in the cluster
$StorageKey=(az storage account keys list --resource-group $RG --account-name $azFileStorage --query "[0].value" -o tsv)
kubectl create secret generic azure-secret `
        --from-literal=azurestorageaccountname=$azFileStorage `
        --from-literal=azurestorageaccountkey=$StorageKey

# Deploy nginx with a volume on azurefiles
code nginx-with-azurefiles-stat-inline.yaml
kubectl apply -f nginx-with-azurefiles-stat-inline.yaml

# Check out Pod
kubectl get pod

# And verify the connectivity of the volume
kubectl exec -it (kubectl get pods -o=jsonpath='{.items[0].metadata.name}') -- bash -c "touch /usr/share/nginx/html/web-app/testfile"
kubectl exec -it (kubectl get pods -o=jsonpath='{.items[0].metadata.name}') -- bash -c "ls -l /usr/share/nginx/html/web-app"

# Renew the key of the storage account
az storage account keys renew -g $RG -n $azFileStorage --key primary -o table

# And verify the connectivity of the volume again
kubectl exec -it (kubectl get pods -o=jsonpath='{.items[0].metadata.name}') -- bash -c "ls -l /usr/share/nginx/html/web-app"

# Retrieve the new key and either patch or delete/create the secret
$StorageKey=(az storage account keys list --resource-group $RG --account-name $azFileStorage --query "[0].value" -o tsv)
kubectl delete secret azure-secret
kubectl create secret generic azure-secret `
        --from-literal=azurestorageaccountname=$azFileStorage `
        --from-literal=azurestorageaccountkey=$StorageKey

# Restart the Deployment
kubectl rollout restart deployment nginx-azfile-static-deployment-inline

# Connectivity is fixed
kubectl exec -it (kubectl get pods -o=jsonpath='{.items[0].metadata.name}') -- bash -c "ls -l /usr/share/nginx/html/web-app"

# Check currently used and quota for H Family vCPUs
# Your values may differ!
az vm list-usage --location $Region -o table | grep 'CurrentValue\|H Family'

# Create cluster
az aks create -g $RG -n $AKSCluster_Limited --node-vm-size $ClusterSize_Limited

# Let's try again
az aks create -g $RG -n $AKSCluster_Limited --node-vm-size $ClusterSize_Limited --node-count 1

# Now quota is fully used!
az vm list-usage --location $Region -o table | grep 'CurrentValue\|H Family'

# Try to scale up
az aks scale -g $RG -n $AKSCluster_Limited --node-count 2

# Try to upgrade
az aks get-upgrades --resource-group $RG --name $AKSCluster_Limited -o table
$TargetVersion=(az aks get-upgrades --resource-group $RG --name $AKSCluster_Limited -o json `
                --query controlPlaneProfile.upgrades[0].kubernetesVersion)
az aks upgrade --resource-group $RG --name $AKSCluster_Limited --kubernetes-version $TargetVersion --yes


# Create a VNet with 256 IP addresses and a Subnet using 128 of them
az network vnet create --resource-group $RG --address-prefixes 10.0.0.0/24 --name SmallVNet `
                                            --subnet-prefixes 10.0.0.0/25 --subnet-name SmallSubnet 

# Retrieve the ID of that Subnet
$SubnetId=(az network vnet subnet show --resource-group $RG --vnet-name SmallVNet --name=SmallSubnet --query id -o tsv)

# Try to create a Cluster with that Subnet using the Azure-CNI plugin and 250 max-pods
az aks create -g $RG -n $AKSCluster-CNI --network-plugin azure --vnet-subnet-id $SubnetId `
            --service-cidr 10.0.0.128/25 --dns-service-ip 10.0.0.130 --max-pods 250 --yes 

# Required IP addresses: 1 per "max pod" per node + 1 for each node
# Try again with 40 max-pods --> 3 nodes + 40 maxpods * 3 nodes = 123 
az aks create -g $RG -n $AKSCluster-CNI --network-plugin azure --vnet-subnet-id $SubnetId `
            --service-cidr 10.0.0.128/25 --dns-service-ip 10.0.0.130 --max-pods 40 --yes 

# Try to scale this Cluster up
az aks scale -g $RG -n $AKSCluster-CNI --node-count 4
Clear-Host