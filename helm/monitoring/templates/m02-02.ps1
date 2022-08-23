cd C:\Users\PSDemo\Desktop\Demos\aks-monitoring\m02
# Create Namespace for Kibana
kubectl create namespace logging
kubectl config set-context --current --namespace=logging

# Deploy elastic search, fluentd and Kibana
kubectl apply -f es-statefulset.yaml
kubectl apply -f es-service.yaml
kubectl apply -f fluentd-es-configmap.yaml
kubectl apply -f fluentd-es-ds.yaml
kubectl apply -f kibana-deployment.yaml
kubectl apply -f kibana-service.yaml

# Check out deployed pods
kubectl get pods

# Retrieve service
kubectl get svc kibana-logging

# Check out Kibana
$KibanaURL="http://" + (kubectl get svc kibana-logging -o jsonpath='{.status.loadBalancer.ingress[0].ip}') + ":5601"
Start-Process $KibanaURL

# Sale nginx
kubectl scale deployment nginx --replicas=10 -n nginx

# Create Namespace for Grafana
kubectl create namespace monitoring
kubectl config set-context --current --namespace=monitoring

# Add Helm repos / update Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update

# Install Prometheus stack (which includes Grafana!)
helm install monitor prometheus-community/kube-prometheus-stack --namespace monitoring

# Check our Pods and Service
kubectl get pods
kubectl get svc monitor-grafana

# Change Service-Type to LoadBalancer
kubectl patch svc monitor-grafana -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc monitor-grafana

# Check our Grafana Portal
# Default credentials:
# Username: admin
# Password: prom-operator
$GrafanaURL="http://" + (kubectl get svc monitor-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}') 
Start-Process $GrafanaURL

#prom-operator

# Scale the nginx deployment
kubectl scale deployment nginx --replicas=15 -n nginx

Clear-Host