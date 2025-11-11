#!/bin/bash
# k8s/deploy.sh - Complete deployment script for Quay.io
# This script automates the application of all manifest files in the correct order

set -e

echo "🚀 Deploying Docling + PySpark to Kubernetes"
echo "=============================================="

# Configuration
NAMESPACE="docling-spark"
QUAY_USERNAME="rishasin"  
IMAGE_NAME="docling-spark"
IMAGE_TAG="latest"
QUAY_IMAGE="quay.io/${QUAY_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "📦 Image: ${QUAY_IMAGE}"

# Step 1: Create namespace
echo ""
echo "☸️  Step 1: Creating namespace..."
kubectl apply -f k8s/base/namespace.yaml

# Step 2: Create RBAC
echo ""
echo "🔐 Step 2: Creating RBAC (ServiceAccount, Role, RoleBinding)..."
kubectl apply -f k8s/base/rbac.yaml

# Step 3: Create image pull secret
echo ""
echo "🔑 Step 3: Creating Quay.io pull secret..."
kubectl apply -f k8s/base/secrets.yaml
echo "✅ Pull secret created from secrets.yaml"

# Step 4: Create storage
echo ""
echo "💾 Step 4: Creating PersistentVolumeClaims..."
kubectl apply -f k8s/base/storage.yaml

# Step 5: Wait for PVCs
echo ""
echo "⏳ Step 5: Waiting for storage to be ready..."
sleep 5  # Give provisioner time to process
kubectl wait --for=condition=Bound pvc/docling-input-pvc -n $NAMESPACE --timeout=120s
kubectl wait --for=condition=Bound pvc/docling-output-pvc -n $NAMESPACE --timeout=120s
echo "✅ Storage ready"

# Step 6: Create ConfigMap
echo ""
echo "⚙️  Step 6: Creating ConfigMap..."
# Update image in configmap
sed "s|quay.io/rishasin/docling-spark:latest|${QUAY_IMAGE}|g" k8s/base/configmap.yaml | kubectl apply -f -

# Step 7: Create Service
echo ""
echo "🌐 Step 7: Creating Service..."
kubectl apply -f k8s/base/service.yaml

# Step 8: Submit Spark job
echo ""
echo "🚀 Step 8: Submitting Spark job..."
# Update image in job manifest
sed "s|quay.io/rishasin/docling-spark:latest|${QUAY_IMAGE}|g" k8s/spark-submit-job.yaml | kubectl apply -f -

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "   kubectl get pods -n $NAMESPACE"
echo ""
echo "📝 View logs:"
echo "   kubectl logs -f -n $NAMESPACE <pod-name>"
echo ""
echo "🌐 Access Spark UI:"
echo "   kubectl port-forward -n $NAMESPACE svc/spark-ui 4040:4040"
echo "   Open: http://localhost:4040"