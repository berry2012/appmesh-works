#!/bin/bash

echo "Deleting the App Mesh virtual services"
kubectl delete virtualservice redis-server -n yelb
kubectl delete virtualservice yelb-db -n yelb
kubectl delete virtualservice yelb-ui -n yelb
kubectl delete virtualservice yelb-appserver -n yelb

echo "Deleting the App Mesh virtual router"
kubectl delete virtualrouter yelb-appserver -n yelb

echo "Deleting the App Mesh virtual nodes"
kubectl delete virtualnode redis-server -n yelb
kubectl delete virtualnode yelb-appserver -n yelb
kubectl delete virtualnode yelb-db -n yelb
kubectl delete virtualnode yelb-ui -n yelb

echo "Deleting the App Mesh mesh"
kubectl delete mesh yelb

echo "Deleting the Yelb deployment"
kubectl delete -f infrastructure/yelb_initial_deployment.yaml

echo "Deleting EKS cluster"
eksctl delete cluster -f cluster.yml

echo "Cleanup finished"