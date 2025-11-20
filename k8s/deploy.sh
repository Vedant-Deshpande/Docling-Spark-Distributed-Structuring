#!/bin/bash
# k8s/deploy.sh - Simplified deployment script for MVP
# This script deploys the Docling + PySpark application to ROSA

set -e

echo "🚀 Deploying Docling + PySpark to ROSA"
echo "======================================"

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

# Step 3: Submit Spark Application
echo ""
echo "🚀 Step 3: Submitting Spark Application..."
kubectl apply -f k8s/docling-spark-app.yaml

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "   kubectl get sparkapplications -n $NAMESPACE"
echo "   kubectl get pods -n $NAMESPACE"
echo ""
echo "📝 View logs:"
echo "   kubectl logs -f docling-spark-job-driver -n $NAMESPACE"
echo ""
echo "🌐 Access Spark UI (when driver is running):"
echo "   kubectl port-forward -n $NAMESPACE svc/docling-spark-job-ui-svc 4040:4040"
echo "   Open: http://localhost:4040"
echo ""
echo "💡 Note: PDFs are processed from /app/assets in the Docker image"
echo "   To process different PDFs, rebuild the image with new files in assets/"
