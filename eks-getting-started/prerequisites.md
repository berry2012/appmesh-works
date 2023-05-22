# Pre-requisite steps

## Install needed tools
Install latest [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
Install latest [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)


## Create Amazon EKS Cluster


create file cluster.yml with the content below:

```
# A simple example of ClusterConfig object:
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: "l3series"
  region: eu-west-1
  version: "1.26"

iam:
  withOIDC: true  


managedNodeGroups:
  - name: mn
    labels: { role: workers }
    instanceType: t3.medium
    desiredCapacity: 1
    minSize: 1
    maxSize: 3      
    privateNetworking: true
    ssh:
        enableSsm: true    

cloudWatch:
 clusterLogging:
   enableTypes: ["audit", "authenticator", "controllerManager"]    

```

```
eksctl create cluster -f cluster.yml
```


## Deploy App Mesh controller

[App Mesh controller for Kubernetes](https://docs.aws.amazon.com/app-mesh/latest/userguide/getting-started-kubernetes.html)



**Add the eks-charts repository to Helm**
```
helm repo add eks https://aws.github.io/eks-charts
```

**Install the App Mesh Kubernetes custom resource definitions (CRD)**

```
kubectl apply -k "https://github.com/aws/eks-charts/stable/appmesh-controller/crds?ref=master"

customresourcedefinition.apiextensions.k8s.io/backendgroups.appmesh.k8s.aws created
customresourcedefinition.apiextensions.k8s.io/gatewayroutes.appmesh.k8s.aws created
customresourcedefinition.apiextensions.k8s.io/meshes.appmesh.k8s.aws created
customresourcedefinition.apiextensions.k8s.io/virtualgateways.appmesh.k8s.aws created
customresourcedefinition.apiextensions.k8s.io/virtualnodes.appmesh.k8s.aws created
customresourcedefinition.apiextensions.k8s.io/virtualrouters.appmesh.k8s.aws created
customresourcedefinition.apiextensions.k8s.io/virtualservices.appmesh.k8s.aws created
```

## Create a Kubernetes namespace for the controller.

```
kubectl create ns appmesh-system

namespace/appmesh-system created
```

**Set the following variables for use in later steps. Replace cluster-name and Region-code with the values for your existing cluster.**

```
export CLUSTER_NAME=l3series
export AWS_REGION=eu-west-1
```

## Create an IAM role, attach the AWSAppMeshFullAccess and AWSCloudMapFullAccess AWS managed policies to it, and bind it to the appmesh-controller Kubernetes service account

```
eksctl create iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --namespace appmesh-system \
    --name appmesh-controller \
    --attach-policy-arn  arn:aws:iam::aws:policy/AWSCloudMapFullAccess,arn:aws:iam::aws:policy/AWSAppMeshFullAccess \
    --override-existing-serviceaccounts \
    --approve \
    --profile staging
```

## Deploy the App Mesh controller. For a list of all configuration options, see Configuration on GitHub.

```
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller    

output:
AWS App Mesh controller installed!
```

## Confirm that the controller version is v1.4.0 or later. You can review the change log on GitHub.

```
kubectl get deployment appmesh-controller \
    -n appmesh-system \
    -o json  | jq -r ".spec.template.spec.containers[].image" | cut -f2 -d ':'

v1.11.0    
```

## Confirm Controller Pods are running

```
% kubectl get pods -n appmesh-system
NAME                                  READY   STATUS    RESTARTS   AGE
appmesh-controller-7bc98bb568-6kbfv   1/1     Running   0          60s


kubectl logs -f -l app.kubernetes.io/name=appmesh-controller -n appmesh-system

kubectl get crds | grep appmesh

kubectl get ValidatingWebhookConfiguration 

kubectl get MutatingWebhookConfiguration
```

## (Optional) - Deploy Container Insight 

[Container Insights on Amazon EKS or Kubernetes](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy-container-insights-EKS.html)


# Deploy App Mesh resources - Example

1. Create an App Mesh service mesh 

```
kubectl apply -f mesh.yaml
```

2. Create an App Mesh virtual node. A virtual node acts as a logical pointer to a Kubernetes deployment.

```
kubectl apply -f virtual-node.yaml
```

- The virtual node represents a Kubernetes service that is created in a later step. 
- The value for hostname is the fully qualified DNS hostname of the actual service that this virtual node represents.

3. Create an App Mesh virtual router. Virtual routers handle traffic for one or more virtual services within your mesh.

```
kubectl apply -f virtual-router.yaml
```

4. Create an App Mesh virtual service. A virtual service is an abstraction of a real service that is provided by a virtual node directly or indirectly by means of a virtual router. Dependent services call your virtual service by its name

```
kubectl apply -f virtual-service.yaml
```

5. Create a Kubernetes service and deployment

```
kubectl apply -f my-service-a.yaml
```

**The value for the app matchLabels selector in the spec must match the value that you specified when you created the virtual node or the sidecar containers won't be injected into the pod**


## Reviewing the App Mesh Resources

```
kubectl describe mesh my-mesh

aws appmesh describe-mesh --mesh-name my-mesh

kubectl describe virtualnode my-service-a -n my-apps

aws appmesh describe-virtual-node --mesh-name my-mesh --virtual-node-name my-service-a_my-apps

kubectl describe virtualrouter my-service-a-virtual-router -n my-apps

aws appmesh describe-virtual-router --virtual-router-name my-service-a-virtual-router_my-apps --mesh-name my-mesh

kubectl describe virtualservice my-service-a -n my-apps

aws appmesh describe-virtual-service --virtual-service-name my-service-a.my-apps.svc.cluster.local --mesh-name my-mesh

kubectl -n my-apps describe pod my-service-a-XXXXXX
```


