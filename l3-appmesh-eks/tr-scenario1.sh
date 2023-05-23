Scenario - Envoy readiness probe failed!


% kg po -n yelb                                          
NAME                              READY   STATUS    RESTARTS   AGE
redis-server-76d7b647dd-2jqwh     1/2     Running   0          16m
yelb-appserver-56d6d6685b-vpvnk   1/2     Running   0          16m
yelb-db-5dfdd5d44f-m2gfm          1/2     Running   0          16m
yelb-ui-56545895f-f7rw5           1/2     Running   0          16m

k describe po yelb-ui-56545895f-f7rw5 -n yelb | grep Events
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  4m14s                  default-scheduler  Successfully assigned yelb/yelb-ui-56545895f-f7rw5 to ip-192-168-149-34.eu-west-1.compute.internal
  Normal   Pulled     4m13s                  kubelet            Container image "840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-proxy-route-manager:v7-prod" already present on machine
  Normal   Created    4m13s                  kubelet            Created container proxyinit
  Normal   Started    4m13s                  kubelet            Started container proxyinit
  Normal   Pulled     4m12s                  kubelet            Container image "mreferre/yelb-ui:0.7" already present on machine
  Normal   Created    4m12s                  kubelet            Created container yelb-ui
  Normal   Started    4m12s                  kubelet            Started container yelb-ui
  Normal   Pulled     4m12s                  kubelet            Container image "840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-envoy:v1.25.1.0-prod" already present on machine
  Normal   Created    4m12s                  kubelet            Created container envoy
  Normal   Started    4m12s                  kubelet            Started container envoy
  Warning  Unhealthy  2m4s (x16 over 4m11s)  kubelet            Readiness probe failed:


% kubectl logs -n yelb -f yelb-ui-56545895f-f7rw5 envoy --since 10s

[2023-05-23 08:53:27.065][16][warning][config] [./source/common/config/grpc_stream.h:163] StreamAggregatedResources gRPC config stream to appmesh-envoy-management.eu-west-1.amazonaws.com:443 closed: 7, Unauthorized to perform appmesh:StreamAggregatedResources for arn:aws:appmesh:eu-west-1:222222222222:mesh/yelb/virtualNode/yelb-ui-virtual-node.
[2023-05-23 08:53:52.190][16][warning][config] [./source/common/config/grpc_stream.h:163] StreamAggregatedResources gRPC config stream to appmesh-envoy-management.eu-west-1.amazonaws.com:443 closed: 7, Unauthorized to perform appmesh:StreamAggregatedResources for arn:aws:appmesh:eu-west-1:222222222222:mesh/yelb/virtualNode/yelb-ui-virtual-node.

% kubectl logs -n yelb -f yelb-db-5dfdd5d44f-m2gfm  envoy --since 10s
[2023-05-23 09:09:35.529][14][warning][config] [./source/common/config/grpc_stream.h:163] StreamAggregatedResources gRPC config stream to appmesh-envoy-management.eu-west-1.amazonaws.com:443 closed: 7, Unauthorized to perform appmesh:StreamAggregatedResources for arn:aws:appmesh:eu-west-1:222222222222:mesh/yelb/virtualNode/yelb-db-virtual-node.

#Root cause
The Kubernetes deployment couldnt stream the configuration for its own App Mesh virtual node due to IAM permission

# Check CTrail 

Event source: appmesh.amazonaws.com
Event name: StreamAggregatedResources

{
    "eventVersion": "1.08",
    "userIdentity": {
        "type": "AssumedRole",
        "principalId": "AROAW52N42IYNFCPPZ72N:i-0b6c05fe66d5800fb",
        "arn": "arn:aws:sts::222222222222:assumed-role/eksctl-l3series-nodegroup-mn-NodeInstanceRole-1A7QG2NG0227F/i-0b6c05fe66d5800fb",
        "accountId": "222222222222",
        "accessKeyId": "ASIAW52N42IYE3XU6PFU",
        "invokedBy": "appmesh.amazonaws.com"
    },
    "eventTime": "2023-05-23T09:12:48Z",
    "eventSource": "appmesh.amazonaws.com",
    "eventName": "StreamAggregatedResources",
    "awsRegion": "eu-west-1",
    "sourceIPAddress": "appmesh.amazonaws.com",
    "userAgent": "appmesh.amazonaws.com",
    "requestParameters": null,
    "responseElements": null,
    "eventID": "4c4d6b8d-24fc-4538-b46b-ec8cd72b9d32",
    "readOnly": false,
    "eventType": "AwsServiceEvent",
    "managementEvent": true,
    "recipientAccountId": "222222222222",
    "serviceEventDetails": {
        "connectionId": "7e489977-f108-4fdd-a5c0-d319883f6cc0",
        "nodeArn": "arn:aws:appmesh:eu-west-1:222222222222:mesh/yelb/virtualNode/redis-server-virtual-node",
        "eventStatus": "ConnectionTerminated",
        "failureReason": "Unauthorized to perform appmesh:StreamAggregatedResources for arn:aws:appmesh:eu-west-1:222222222222:mesh/yelb/virtualNode/redis-server-virtual-node."
    },
    "eventCategory": "Management"
}

# Resolution
 Enable proxy authorization. 
- Option 1: We recommend that you enable each Kubernetes deployment to stream only the configuration for its own App Mesh virtual node.
i.e create IRSA and attach SA to the deployment

```
cat << EOF > proxy-auth.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "appmesh:StreamAggregatedResources",
            "Resource": [
                "arn:aws:appmesh:Region-code:111122223333:mesh/my-mesh/virtualNode/my-service-a_my-apps"
            ]
        }
    ]
}
EOF

aws iam create-policy --policy-name my-policy --policy-document file://proxy-auth.json
```

```
eksctl create iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --namespace my-apps \
    --name my-service-a \
    --attach-policy-arn  arn:aws:iam::111122223333:policy/my-policy \
    --override-existing-serviceaccounts \
    --approve
```    

```
    spec:
      serviceAccountName: my-service-a
```      

- Option 2: Attach AWSAppMeshEnvoyAccess permission to the worker node IAM role
- App Mesh Envoy policy for accessing Virtual Node configuration.

```
aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess \
    --role-name $node_role_name
```    

- Delete the pods for the new configuration to take effect

```
kubectl -n yelb delete pods --all
```

% kubectl -n yelb get pods                             
NAME                              READY   STATUS    RESTARTS   AGE
redis-server-76d7b647dd-7cfk5     2/2     Running   0          2m49s
yelb-appserver-56d6d6685b-zw6fk   2/2     Running   0          2m49s
yelb-db-5dfdd5d44f-648bv          2/2     Running   0          2m49s
yelb-ui-56545895f-hxhr2           2/2     Running   0          2m49s

