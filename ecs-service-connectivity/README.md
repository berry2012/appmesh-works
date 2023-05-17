# Service Connectivity Inside and Outside the AWS App Mesh (ECS/Fargate)


Reference - https://aws.amazon.com/blogs/containers/service-connectivity-inside-and-outside-the-mesh-using-aws-app-mesh-ecs-fargate/


## Update the variables in settings.sample
**You can use your default VPC**

```
export AWS_ACCOUNT_ID=<account-id>
export AWS_DEFAULT_REGION="<region>"
# Get the Envoy image URL from https://docs.aws.amazon.com/app-mesh/latest/userguide/envoy.html
export ENVOY_IMAGE="<ENVOY-IMAGE-URL>"
export VPC="<vpc-id>"
export SUBNET_1="<subnet-id>"
export SUBNET_2="<subnet-id>"
```

```
# Run the below command to rename the settings.sample file to .settings
mv sample.settings .settings

# Run the below command. This will build the docker images for yelb-ui and yelb-appserver. This will then deploy the yelb application should take about 5-10 minutes to complete
./deploy_yelb.sh

# Step4: Run the below to setup the db table for votes
./deploy_db.sh
```

## Step 3a: Mesh components

```
# Create a mesh
aws appmesh create-mesh --mesh-name yelb
cd mesh/
# Please take a moment to read the script files for your understanding.
# Create App Mesh Components for Yelb-DB
sh ./yelb-appmesh-db.sh
# Create App Mesh Components for Yelb-Redis
sh ./yelb-appmesh-redis.sh
# Create App Mesh Components for External API (recipepuppy.com)
sh ./yelb-appmesh-recipe.sh
# Create App Mesh Components for Yelb-AppServer
sh ./yelb-appmesh-appserver.sh
# Create App Mesh Components for Yelb-UI
sh ./yelb-appmesh-ui.sh
# Create Virtual Gateway, Routes
sh ./yelb-appmesh-gateway.sh
```

Follow the reference link for the remainder of the steps