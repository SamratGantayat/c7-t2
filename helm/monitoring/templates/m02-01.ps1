cd C:\Users\PSDemo\Desktop\Demos\aks-monitoring\m02

# Get cluster details and open cluster in portal
$ClusterID=(az aks show -g $RG -n $AKSCluster --query id -o tsv)
$TenantID=(az aks show -g $RG -n $AKSCluster --query identity.tenantId -o tsv)
$ClusterURL="https://portal.azure.com/#@"+ $TenantID + "/resource" + $ClusterID

Start-Process $ClusterURL

# Create Namespace
kubectl create namespace nginx
kubectl config set-context --current --namespace=nginx

# Create a Deployment
kubectl create deployment nginx --image=nginx 

# Verify Deployment
kubectl get pods 

# Scale up
kubectl scale deployment nginx --replicas=20
kubectl get pods

# Scale down
kubectl scale deployment nginx --replicas=2 
kubectl get pods 
Clear-Host