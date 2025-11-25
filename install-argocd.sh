#!/bin/bash

set -euo pipefail

echo "Installing ArgoCD..."

# Clean up previous ArgoCD installation if any
kubectl delete namespace argocd --ignore-not-found=true --context kind-gitops-cluster

# Create ArgoCD namespace
kubectl create namespace argocd --context kind-gitops-cluster

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --context kind-gitops-cluster

echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd --context kind-gitops-cluster

echo "ArgoCD installed successfully."

echo "Retrieving initial admin password..."
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --context kind-gitops-cluster | base64 -d)
echo "ArgoCD initial admin password: $ARGO_PWD"
echo "You can access ArgoCD UI at: https://localhost:8080"

# Source the onboard-app.sh script to make its functions available
source ./onboard-app.sh

echo "Onboarding initial applications..."
./onboard-app.sh hello-gitops-dev dev
./onboard-app.sh hello-gitops-prod prod
echo "Initial ArgoCD Applications onboarded successfully."
