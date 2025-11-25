#!/bin/bash

# --- Configuration ---
APP_REPO_PATH="../app-repo"
GITOPS_REPO_PATH="."
IMAGE_NAME="hello-gitops"
KIND_CLUSTER_NAME="argocd-demo"
DEV_VALUES_FILE="$GITOPS_REPO_PATH/apps/hello-gitops/values-dev.yaml"
PROD_VALUES_FILE="$GITOPS_REPO_PATH/apps/hello-gitops/values-prod.yaml"

# --- Build and Tag Docker Image ---
echo "Building Docker image for $IMAGE_NAME..."
cd $APP_REPO_PATH
docker build -t $IMAGE_NAME:latest .
cd -

# Generate a unique tag (e.g., timestamp or commit SHA)
IMAGE_TAG=$(date +%Y%m%d%H%M%S)
docker tag $IMAGE_NAME:latest $IMAGE_NAME:$IMAGE_TAG

echo "Image built and tagged: $IMAGE_NAME:$IMAGE_TAG"

# --- Load image into Kind cluster ---
echo "Loading image into Kind cluster: $KIND_CLUSTER_NAME"
kind load docker-image $IMAGE_NAME:$IMAGE_TAG --name $KIND_CLUSTER_NAME

# --- Update Deployment Manifests in GitOps Repo ---
echo "Updating deployment manifests with new image tag..."

# Update Dev values file
sed -i '' "s|tag: \"latest\"|tag: \"$IMAGE_TAG\"|g" $DEV_VALUES_FILE
echo "Updated $DEV_VALUES_FILE with image tag: $IMAGE_TAG"

# Update Prod values file
sed -i '' "s|tag: \"latest\"|tag: \"$IMAGE_TAG\"|g" $PROD_VALUES_FILE
echo "Updated $PROD_VALUES_FILE with image tag: $IMAGE_TAG"

echo "CI/CD process completed. The GitOps repository now has updated image tags."
echo "You would typically commit and push these changes to your remote GitOps repository."
