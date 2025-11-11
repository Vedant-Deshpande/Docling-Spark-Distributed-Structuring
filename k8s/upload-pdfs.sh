#!/bin/bash
# k8s/upload-pdfs.sh
# Creates a temporary busybox Pod that mounts the docling-input-pvc. 
# It then uses kubectl cp to copy your local PDF files from the assets/ directory into the mounted PVC inside the running temporary pod. 
# This is how you load your input data into the cluster storage.

NAMESPACE="docling-spark"
PVC_NAME="docling-input-pvc"

echo "📤 Uploading PDFs to Kubernetes storage..."

# Create a temporary pod with the PVC mounted
kubectl run -n $NAMESPACE uploader --image=busybox --rm -it --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "uploader",
      "image": "busybox",
      "command": ["sleep", "3600"],
      "volumeMounts": [{
        "name": "input-volume",
        "mountPath": "/input"
      }]
    }],
    "volumes": [{
      "name": "input-volume",
      "persistentVolumeClaim": {
        "claimName": "'$PVC_NAME'"
      }
    }]
  }
}'

# Now copy files
kubectl cp assets/ $NAMESPACE/uploader:/input/

echo "✅ Upload complete!"