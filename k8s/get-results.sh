#!/bin/bash
# k8s/get-results.sh
# Finds the running Spark Driver Pod and uses kubectl cp to copy the processed results from the mounted output path (/app/output) on the Driver Pod back to your local machine (./output-from-k8s).

NAMESPACE="docling-spark"

echo "📥 Downloading results from Kubernetes..."

# Get the driver pod name
DRIVER_POD=$(kubectl get pods -n $NAMESPACE -l spark-role=driver -o jsonpath='{.items[0].metadata.name}')

if [ -z "$DRIVER_POD" ]; then
    echo "❌ No driver pod found. Job may not be running."
    exit 1
fi

# Copy results
kubectl cp $NAMESPACE/$DRIVER_POD:/app/output ./output-from-k8s

echo "✅ Results downloaded to: ./output-from-k8s"