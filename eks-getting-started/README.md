# Getting started with AWS App Mesh and Amazon EKS

**Blog Reference - https://aws.amazon.com/blogs/containers/getting-started-with-app-mesh-and-eks/**


```
kg all -n yelb
NAME                                   READY   STATUS    RESTARTS   AGE
pod/redis-server-74556bbcb7-bjtmk      2/2     Running   0          14h
pod/yelb-appserver-d584bb889-s656r     2/2     Running   0          83m
pod/yelb-appserver-v2-5b7d84bc-5qm4s   2/2     Running   0          14h
pod/yelb-db-694586cd78-4r58c           2/2     Running   0          14h
pod/yelb-ui-798667d648-4x9v9           2/2     Running   0          83m

NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)        AGE
service/redis-server        ClusterIP      10.100.245.6     <none>                                                                    6379/TCP       267d
service/yelb-appserver      ClusterIP      10.100.246.110   <none>                                                                    4567/TCP       267d
service/yelb-appserver-v2   ClusterIP      10.100.184.70    <none>                                                                    4567/TCP       267d
service/yelb-db             ClusterIP      10.100.140.195   <none>                                                                    5432/TCP       267d
service/yelb-ui             LoadBalancer   10.100.133.242   a087eedfbe20441ab95ba6fa0709927c-1614200199.eu-west-1.elb.amazonaws.com   80:31338/TCP   267d

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/redis-server        1/1     1            1           267d
deployment.apps/yelb-appserver      1/1     1            1           267d
deployment.apps/yelb-appserver-v2   1/1     1            1           267d
deployment.apps/yelb-db             1/1     1            1           267d
deployment.apps/yelb-ui             1/1     1            1           267d

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/redis-server-74556bbcb7      1         1         1       267d
replicaset.apps/yelb-appserver-d584bb889     1         1         1       267d
replicaset.apps/yelb-appserver-v2-5b7d84bc   1         1         1       267d
replicaset.apps/yelb-db-694586cd78           1         1         1       267d
replicaset.apps/yelb-ui-798667d648           1         1         1       267d

NAME                                           ARN                                                                                            AGE
virtualrouter.appmesh.k8s.aws/yelb-appserver   arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualRouter/yelb-appserver-virtual-router   267d

NAME                                            ARN                                                                                           AGE
virtualnode.appmesh.k8s.aws/redis-server        arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualNode/redis-server-virtual-node        267d
virtualnode.appmesh.k8s.aws/yelb-appserver      arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualNode/yelb-appserver-virtual-node      267d
virtualnode.appmesh.k8s.aws/yelb-appserver-v2   arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualNode/yelb-appserver-virtual-node-v2   267d
virtualnode.appmesh.k8s.aws/yelb-db             arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualNode/yelb-db-virtual-node             267d
virtualnode.appmesh.k8s.aws/yelb-ui             arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualNode/yelb-ui-virtual-node             267d

NAME                                            ARN                                                                              AGE
virtualservice.appmesh.k8s.aws/redis-server     arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualService/redis-server     267d
virtualservice.appmesh.k8s.aws/yelb-appserver   arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualService/yelb-appserver   267d
virtualservice.appmesh.k8s.aws/yelb-db          arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualService/yelb-db          267d
virtualservice.appmesh.k8s.aws/yelb-ui          arn:aws:appmesh:eu-west-1:520817024429:mesh/yelb/virtualService/yelb-ui          267d

```
