cd C:\Users\PSDemo\Desktop\Demos\aks-monitoring\m02
# Check for prerequisites 
# https://helm.sh/docs/intro/install/
helm version

# Set variables to be used in the scripts in other demos
$Region="eastus"
$RG="AKSRG"
$Sub=""
$AKSCluster="AKSCluster"
$AKSCluster_Limited="AKSCluster-Limited"
$AKSCluster_CNI="AKSCluster-CNI"
$ClusterSize="Standard_DS4_v2"
$ClusterSize_Limited="Standard_H8"
$LAWS_Name="AKS-LAWS"

az login
az account set -s $Sub

# Create an RG and AKS cluster first
az group create -l $Region -n $RG
az aks create -g $RG -n $AKSCluster --node-vm-size $ClusterSize --generate-ssh-keys
# Get the credentials and check the connectivity
az aks get-credentials -g $RG -n $AKSCluster --overwrite-existing
kubectl get nodes

# Create Log Analytics Workspace
az monitor log-analytics workspace create --resource-group $RG --workspace-name $LAWS_Name
Clear-Host