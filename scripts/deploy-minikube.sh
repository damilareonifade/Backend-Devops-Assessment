#!/usr/bin/env bash
set -e

echo "===================================="
echo "🚀 Starting Minikube Deployment"
echo "------------------------------------"

# === Configuration ===
export COMMIT_SHA1=${COMMIT_SHA1:-latest}
export IMAGE_NAME=upi-os
export UNIQUE_ID=$(date +%s)
export DOMAIN=${APP_DOMAIN:-"upi.local"}

echo "🧱 IMAGE_NAME:   ${IMAGE_NAME}"
echo "🏷️  COMMIT_SHA1:  ${COMMIT_SHA1}"
echo "🆔 UNIQUE_ID:     ${UNIQUE_ID}"
echo "🌍 DOMAIN:        ${DOMAIN}"
echo "===================================="

# === Prerequisite checks ===
for cmd in kubectl envsubst minikube docker; do
  if ! command -v $cmd &> /dev/null; then
    echo "❌ '$cmd' not installed. Please install it first."
    exit 1
  fi
done

# === Use Minikube's Docker daemon ===
echo "🔧 Using Minikube's Docker environment..."
eval $(minikube -p minikube docker-env)

# === Build Docker image inside Minikube ===
echo "🐳 Building Docker image inside Minikube..."
docker build -t ${IMAGE_NAME}:${COMMIT_SHA1} .

# === Verify image exists inside Minikube ===
echo "🔍 Verifying image inside Minikube..."
if ! minikube ssh "docker images | grep ${IMAGE_NAME}:${COMMIT_SHA1}" >/dev/null; then
  echo "❌ Image not found inside Minikube environment!"
  exit 1
fi
echo "✅ Image successfully built inside Minikube!"

# === Prepare rendered directory ===
rm -rf rendered && mkdir -p rendered/jobs rendered/kubetest

# === Substitute environment variables in YAML templates ===
echo "🧩 Rendering Kubernetes YAML templates..."
for file in ./jobs/*.yaml ./kubetest/*.yaml; do
  [ -e "$file" ] || continue
  out="rendered/$(basename "$file")"
  echo "   → Rendering $(basename "$file") → $out"
  envsubst '$COMMIT_SHA1 $IMAGE_NAME $DOMAIN $UNIQUE_ID' < "$file" > "$out"
done

# === Run migration job ===
echo "🛠️  Running migration Job..."

# Clean up old migration jobs
kubectl delete job -l job-type=migration --ignore-not-found=true

# Apply new migration job from rendered folder
JOB_FILE="rendered/upi-job.yaml"
JOB_NAME="upi-migration-${UNIQUE_ID}"

kubectl apply -f "$JOB_FILE"

echo "⏳ Waiting for migration job (${JOB_NAME}) to complete..."
if ! kubectl wait --for=condition=complete "job/${JOB_NAME}" --timeout=300s -n default; then
  echo "❌ Migration failed or timed out. Fetching logs..."
  POD_NAME=$(kubectl get pods --selector=job-name=${JOB_NAME} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [ -n "$POD_NAME" ]; then
    kubectl logs "$POD_NAME" || echo "⚠️ Could not fetch logs."
  else
    echo "⚠️ No pod found for ${JOB_NAME}."
  fi
  echo "🧹 Cleaning up failed job..."
  kubectl delete job "${JOB_NAME}" --ignore-not-found=true
  exit 1
fi

echo "✅ Migration completed successfully!"

# === Deploy app ===
echo "🚀 Applying Kubernetes manifests..."
kubectl apply -f rendered/

# === Verify rollouts ===
deployments=("upi-os" "upi-os-horizon" "prometheus")
for dep in "${deployments[@]}"; do
  echo "🔄 Checking rollout for ${dep}..."
  if ! kubectl rollout status "deployment/${dep}" --timeout=300s; then
    echo "❌ Rollout failed for ${dep}"
    exit 1
  fi
done

echo "✅ All deployments rolled out successfully!"
echo "🎉 Deployment completed successfully!"
