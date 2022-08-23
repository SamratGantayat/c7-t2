cd C:\Users\PSDemo\Desktop\Demos\aks-monitoring\m03
# Retrieve the IP addresses of our cluster nodes
kubectl get nodes -o=custom-columns=NODE:.metadata.name,IP:.status.addresses[1].address

# Open a second PS session
# Create a temporary Pod within your cluster
kubectl run -it --rm aks-ssh --image=mcr.microsoft.com/aks/fundamental/base-ubuntu:v0.0.11
# For Windows clusters add:
#  --overrides='{"apiVersion":"v1","spec":{"nodeSelector":{"beta.kubernetes.io/os":"linux"}}}'

# Install SSH client
apt-get update &&  apt-get install openssh-client -y

# From the original PS session, copy your SSH key to the Pod
cp ~/.ssh/id_rsa id_rsa
kubectl cp id_rsa aks-ssh:/id_rsa
Remove-Item .\id_rsa

# In Pod PS connection
# Adjust permissions on key
chmod 0400 /id_rsa

# ssh into one of the hosts
ssh -i /id_rsa azureuser@10.240.0.4

# User journalctl to retrieve kubelet log
sudo journalctl -u kubelet -o cat


exit
exit

az group delete -n $RG
Clear-Host