#!/bin/bash

set -euo pipefail

APP_NAME="$1" #"hello-gitops"
ENV="$2"

if [ -z "$APP_NAME" ] || [ -z "$ENV" ]; then
  echo "Usage: $0 <app-name> <environment>"
  echo "Example: $0 my-new-app dev"
  exit 1
fi

GITOPS_REPO_PATH="."
ARGO_APP_OVERLAY_PATH="$GITOPS_REPO_PATH/applications/overlays/$APP_NAME-$ENV"
ARGO_APP_TEMPLATE="$GITOPS_REPO_PATH/applications/overlays/template-app/kustomization-template.yaml"
APP_HELM_VALUES_PATH="$GITOPS_REPO_PATH/apps/$APP_NAME"
APP_HELM_VALUES_TEMPLATE="$GITOPS_REPO_PATH/apps/template-app/values-template.yaml"

echo "Onboarding application '$APP_NAME' for environment '$ENV'..."

# --- Create directory structure for ArgoCD Application Overlay ---
mkdir -p "$ARGO_APP_OVERLAY_PATH"
echo "Created directory: $ARGO_APP_OVERLAY_PATH"

# --- Copy and customize ArgoCD Application Overlay ---
# Generate and write the customized ArgoCD Application overlay directly
cat <<EOF > "$ARGO_APP_OVERLAY_PATH/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base

patches:
  - target:
      group: argoproj.io
      version: v1alpha1
      kind: Application
      name: REPLACE_APP_NAME-REPLACE_ENV # This must match the base argocd-app.yaml placeholder
    patch: |-
      - op: replace
        path: /metadata/name
        value: $APP_NAME-$ENV
      - op: replace
        path: /spec/destination/namespace
        value: $ENV
      - op: replace
        path: /spec/source/helm/valueFiles
        value:
          - ../../../apps/$APP_NAME/values-$ENV.yaml
      - op: replace
        path: /spec/source/path
        value: apps/$APP_NAME
EOF
echo "Customized ArgoCD Application overlay for $APP_NAME in $ENV."

# --- Create directory and copy template for application Helm values ---
mkdir -p "$APP_HELM_VALUES_PATH"
if [ -f "$APP_HELM_VALUES_TEMPLATE" ]; then
  cp "$APP_HELM_VALUES_TEMPLATE" "$APP_HELM_VALUES_PATH/values-$ENV.yaml"
  echo "Copied Helm values template to: $APP_HELM_VALUES_PATH/values-$ENV.yaml"
  # Optional: Customize generic values file if needed, e.g., default replica count
  # sed -i '' "s|REPLACE_APP_NAME|$APP_NAME|g" "$APP_HELM_VALUES_PATH/values-$ENV.yaml"
else
  echo "Warning: Helm values template not found at $APP_HELM_VALUES_TEMPLATE. Please create it manually."
fi


# --- Apply the new ArgoCD Application to the cluster ---
echo "Applying ArgoCD Application for $APP_NAME in $ENV..."
kubectl apply -k "$ARGO_APP_OVERLAY_PATH" -n argocd
echo "ArgoCD Application for $APP_NAME in $ENV applied successfully."

echo "Application '$APP_NAME' onboarded to ArgoCD for environment '$ENV'."
