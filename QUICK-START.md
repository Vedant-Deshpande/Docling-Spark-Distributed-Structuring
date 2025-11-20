# 🚀 Quick Start - 3 Commands to Deploy

## Prerequisites
- ✅ ROSA cluster with Kubeflow Spark Operator installed
- ✅ `kubectl` configured to access your cluster
- ✅ Docker with buildx support
- ✅ Quay.io repository (public) at `quay.io/rishasin/docling-spark`

## 🎯 Deploy in 3 Steps

### Step 1: Build & Push Docker Image (5-10 minutes)

```bash
cd /Users/roburishabh/Github/Docling-Spark-Distributed-Structuring

docker buildx build --platform linux/amd64 \
  -t quay.io/rishasin/docling-spark:latest \
  --push .
```

**What this does:**
- Builds Docker image with all dependencies (including `libgl1` fix)
- Includes 3 sample PDFs at `/app/assets/`
- Pushes to Quay.io registry

### Step 2: Deploy to ROSA (30 seconds)

```bash
chmod +x k8s/deploy.sh k8s/verify-deployment.sh
./k8s/deploy.sh
```

**What this does:**
- Creates `docling-spark` namespace
- Sets up RBAC (ServiceAccount, Role, RoleBinding)
- Submits SparkApplication to the cluster

### Step 3: Verify & View Results (1-2 minutes)

```bash
# Verify deployment
./k8s/verify-deployment.sh

# Watch the job (wait for driver pod to start)
kubectl logs -f docling-spark-job-driver -n docling-spark
```

**What to expect:**
- Driver pod starts in ~30 seconds
- 2 executor pods start
- PDFs are processed in parallel
- Results appear in logs

## 📊 Expected Output

```
📄 ENHANCED PDF PROCESSING WITH PYSPARK + DOCLING
======================================================================

📂 Step 1: Getting list of PDF files...
   ✅ Found PDF: 2203.01017v2.pdf
   ✅ Found PDF: 2206.01062.pdf
   ✅ Found PDF: 2305.03393v1.pdf
   Found 3 files to process

⚙️  Step 2: Registering the processing function...
   ✅ Function registered

🔄 Step 3: Processing files...
   Spark is now distributing work to workers...

📊 Step 4: Organizing results...

✅ Step 5: Results are ready!

📊 The results:
+----------------------------+-------+--------------------+
|document_path               |success|content             |
+----------------------------+-------+--------------------+
|/app/assets/2203.01017v2.pdf|  true |# Document Title... |
|/app/assets/2206.01062.pdf  |  true |# Document Title... |
|/app/assets/2305.03393v1.pdf|  true |# Document Title... |
+----------------------------+-------+--------------------+

📈 Analysis:
   Total files: 3
   ✅ Successful: 3
   ❌ Failed: 0

✅ ALL DONE!
```

## 🎨 View Spark UI

While the job is running:

```bash
kubectl port-forward -n docling-spark svc/docling-spark-job-ui-svc 4040:4040
```

Then open: http://localhost:4040

## 🔄 Run Again

To process the same PDFs again:

```bash
kubectl delete sparkapplication docling-spark-job -n docling-spark
kubectl apply -f k8s/docling-spark-app.yaml
```

## 📝 Process Different PDFs

1. Add your PDFs to `assets/` folder
2. Rebuild image: `docker buildx build --platform linux/amd64 -t quay.io/rishasin/docling-spark:latest --push .`
3. Redeploy: `kubectl delete sparkapplication docling-spark-job -n docling-spark && kubectl apply -f k8s/docling-spark-app.yaml`

## 🐛 Troubleshooting

### Build fails or takes too long?
- Ensure Docker Desktop has enough resources (4GB+ RAM, 2+ CPUs)
- Check internet connection for downloading dependencies

### Pods stay in "Pending"?
- Check Spark Operator: `kubectl get pods -n kubeflow-spark-operator`
- Check events: `kubectl get events -n docling-spark --sort-by='.lastTimestamp'`

### Job fails immediately?
- Check logs: `kubectl logs docling-spark-job-driver -n docling-spark`
- Verify image was pushed: `docker pull quay.io/rishasin/docling-spark:latest`

### No output in logs?
- Wait 30-60 seconds for driver pod to start
- Check pod status: `kubectl get pods -n docling-spark`

## 📚 More Information

- **Detailed Setup**: See [MVP-SETUP.md](./MVP-SETUP.md)
- **Local Development**: See [README.md](./README.md)
- **Architecture**: See [README.md#architecture-deep-dive](./README.md#architecture-deep-dive)

## ✅ Success Criteria

You'll know it's working when you see:
- ✅ Driver pod in "Running" state
- ✅ 2 executor pods in "Running" state
- ✅ Logs showing "Found 3 files to process"
- ✅ Logs showing "✅ Successful: 3"
- ✅ Job completes with "✅ ALL DONE!"

---

**Time to complete**: ~10-15 minutes total (including build time)

**Cost**: Free tier on ROSA (if within limits)

