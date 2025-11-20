# 🚀 Docling + PySpark: Distributed PDF Processing

A production-ready system for processing PDF documents at scale using Docling and Apache Spark. Extract text, tables, and metadata from thousands of PDFs in parallel.

## ✨ Features

- ✅ **Distributed Processing**: Process thousands of PDFs in parallel using Apache Spark
- ✅ **High-Quality Extraction**: Powered by Docling's modern PDF processing pipeline
- ✅ **Production-Ready**: Comprehensive error handling and fault tolerance
- ✅ **Kubernetes/ROSA Ready**: Deploy on Red Hat OpenShift with Kubeflow Spark Operator
- ✅ **Configurable**: Easily adjust workers, threads, and processing options
- ✅ **Fast**: ~14 seconds per PDF (19 pages) with default settings
- ✅ **Scalable**: Designed to scale from laptop to cloud

## 🎯 Deployment Options

### 🐳 **ROSA/Kubernetes (Recommended for Production)**
Deploy on Red Hat OpenShift Service on AWS with the Kubeflow Spark Operator.

👉 **[See MVP-SETUP.md for quick deployment guide](./MVP-SETUP.md)**

### 💻 **Local Development**
Run on your laptop for development and testing (see below).

## 📋 Table of Contents
- [Quick Start (Local)](#-quick-start)
- [ROSA/Kubernetes Deployment](./MVP-SETUP.md)
- [How It Works](#-how-it-works)
- [Configuration](#️-configuration)
- [Performance Tuning](#-performance-tuning)
- [Understanding the Output](#-understanding-the-output)
- [Troubleshooting](#-troubleshooting)
- [Architecture Deep Dive](#-architecture-deep-dive)



## 🚀 Quick Start

### Prerequisites

```bash
# macOS
brew install openjdk@11

# Ubuntu/Debian
sudo apt-get install openjdk-11-jdk

# Verify installation
java -version
```

### Installation

```bash
# 1. Clone the repository
git clone <your-repo>
cd Docling-Spark-Distributed-Structuring

# 2. Create virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt
```

### Run Your First Job

```bash
# Process PDFs with default settings
python scripts/run_spark_job.py
```

**Expected Output:**
```
✅ Spark session created with 4 workers
📂 Found 3 files to process
🔄 Processing files...
✅ 2 PDFs processed successfully
📊 Total content extracted: 1,076,742 characters
💾 Results saved to: output/results.jsonl/
```

## 🏗️ How It Works

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  YOUR COMPUTER                                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │  SPARK DRIVER (run_spark_job.py)                │    │
│  │  - Orchestrates everything                      │    │
│  │  - Distributes PDFs to workers                  │    │
│  │  - Collects results                             │    │
│  └─────────────────────────────────────────────────┘    │
│                       │                                 │
│         ┌─────────────┼─────────────┬─────────────┐     │
│         ▼             ▼             ▼             ▼     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │Worker 1  │  │Worker 2  │  │Worker 3  │  │Worker 4  │ │
│  │          │  │          │  │          │  │          │ │
│  │Thread 1◯ │  │Thread 1◯ │  │Thread 1◯ │  │Thread 1◯ │ │
│  │Thread 2◯ │  │Thread 2◯ │  │Thread 2◯ │  │Thread 2◯ │ │
│  │          │  │          │  │          │  │          │ │
│  │Docling   │  │Docling   │  │Docling   │  │Docling   │ │
│  │Processor │  │Processor │  │Processor │  │Processor │ │
│  │          │  │          │  │          │  │          │ │
│  │PDF A     │  │PDF B     │  │PDF C     │  │PDF D     │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Processing Flow

1. **Spark Driver** starts and creates 4 worker processes
2. **Driver** discovers PDFs from the `assets/` folder
3. **PDFs are distributed** across workers (round-robin)
4. **Each worker:**
   - Imports the `docling_module` package
   - Creates a Docling processor instance
   - Processes assigned PDFs using 2 threads per PDF
   - Returns structured results (success, content, metadata, errors)
5. **Driver collects** all results into a DataFrame
6. **Results saved** as JSONL format in `output/results.jsonl/`

### Key Components

```
scripts/
├── docling_module/
│   ├── __init__.py          # Simple API: docling_process(file_path)
│   └── processor.py         # Core processor with OOP design
└── run_spark_job.py         # Main Spark orchestration script
```

## ⚙️ Configuration

### Spark Settings (Number of Workers)

Edit `scripts/run_spark_job.py` at **lines 103-112**:

```python
spark = SparkSession.builder \
    .appName("DoclingSparkJob") \
    .master("local[4]") \                     # 4 workers (change this!)
    .config("spark.executor.memory", "2g") \  # RAM per worker
    .config("spark.driver.memory", "2g") \    # Driver RAM
    .getOrCreate()
```

**Configuration Options:**

| Setting | Default | Description | Recommendation |
|---------|---------|-------------|----------------|
| `local[N]` | `local[4]` | Number of workers | Set to number of CPU cores |
| `executor.memory` | `2g` | RAM per worker | 2-4g depending on PDF size |
| `driver.memory` | `2g` | Driver RAM | 2g is usually sufficient |

**Example configurations:**

```python
# Small machine (4 cores, 8 GB RAM)
.master("local[2]") \
.config("spark.executor.memory", "2g")

# Medium machine (8 cores, 16 GB RAM) - RECOMMENDED
.master("local[4]") \
.config("spark.executor.memory", "3g")

# Large machine (16 cores, 32 GB RAM)
.master("local[8]") \
.config("spark.executor.memory", "3g")
```

### Docling Settings (Processing Options)

Edit `scripts/docling_module/processor.py` at **lines 62-84**:

```python
@dataclass
class DocumentConfig:
    # What to extract
    extract_tables: bool = True        # Extract tables
    extract_images: bool = True        # Extract images
    ocr_enabled: bool = False          # OCR for scanned PDFs
    
    # Performance settings
    num_threads: int = 2               # Threads per PDF (IMPORTANT!)
    accelerator_device: str = "cpu"    # MUST be "cpu" for Spark
    timeout_per_document: int = 300    # 5 min timeout
    
    # Enrichment (disabled for performance)
    enrich_code: bool = False
    enrich_formula: bool = False
    enrich_picture_classes: bool = False
    enrich_picture_description: bool = False
```

**Key Settings to Change:**

| Setting | Default | When to Change | Impact |
|---------|---------|----------------|--------|
| `num_threads` | 2 | **Change to 4** for speed | 30% faster processing |
| `ocr_enabled` | False | Enable for scanned PDFs | Slower but needed for images |
| `accelerator_device` | "cpu" | **Never change** | GPU causes worker crashes |
| `extract_tables` | True | Disable if no tables | Slightly faster |

### Input/Output Configuration

Edit `scripts/run_spark_job.py` :

```python
# Change input directory
assets_dir = Path(__file__).parent.parent / "assets"
pdf_path = assets_dir / "2206.01062.pdf"

# Or read from a list
with open('pdf_list.txt', 'r') as f:
    file_list = [(line.strip(),) for line in f if line.strip()]

# Output path is at line 165
output_path = Path(__file__).parent.parent / "output" / "results.jsonl"
```

## 🎯 Performance Tuning

### Current Performance

**Default Configuration:**
- Workers: 4
- Threads per worker: 2
- Total parallel threads: 8
- Speed: ~14 seconds per 19-page PDF
- Throughput: ~17 PDFs per minute

### Optimization Strategy

#### 1. **Increase Threads Per Worker** (Fastest Improvement!)

**Change:** `num_threads: int = 2` → `num_threads: int = 4`

```python
# In processor.py line 72:
num_threads: int = 4  # ⚡ Doubles parallelism per PDF
```

**Impact:**
- ✅ **~30% faster** per PDF (~10 seconds instead of 14)
- ✅ Better CPU utilization
- ✅ Minimal memory increase (threads share resources)
- ⚠️ Requires sufficient CPU cores

**Math:** 4 workers × 4 threads = **16 parallel threads**

#### 2. **Add More Workers**

**Change:** `.master("local[4]")` → `.master("local[8]")`

```python
# In run_spark_job.py line 105:
.master("local[8]")  # ⚡ Double the workers
```

**Impact:**
- ✅ 2× more PDFs processed simultaneously
- ⚠️ Requires more RAM (8 workers × 2GB = 16GB)
- ⚠️ Only helps if you have many PDFs to process

**When to use:** Large batches (100+ PDFs)

#### 3. **Optimize Memory**

```python
# Reduce memory to fit more workers
.config("spark.executor.memory", "1g")  # Instead of 2g
.master("local[8]")  # Now you can run 8 workers with 8GB RAM
```
---
### Understanding Threads vs Workers

**Workers (Processes):**
- Separate Python processes
- Complete isolation (own memory)
- Process different PDFs simultaneously
- More workers = more PDFs at once

**Threads (Per Worker):**
- Share memory within a worker
- Process pages of the same PDF in parallel
- More threads = faster single PDF processing

**Example:**
```
4 workers × 2 threads = 8 total threads
├─ Worker 1 (2 threads) → Processing PDF_A (pages 1-2, 3-4, ...)
├─ Worker 2 (2 threads) → Processing PDF_B (pages 1-2, 3-4, ...)
├─ Worker 3 (2 threads) → Processing PDF_C (pages 1-2, 3-4, ...)
└─ Worker 4 (2 threads) → Processing PDF_D (pages 1-2, 3-4, ...)
```

For more details, see: [thread_explanation.md](thread_explanation.md)

## 📊 Understanding the Output

### Output Structure

Results are saved as **JSONL** (JSON Lines) format:
```
output/results.jsonl/
├── part-00000-xxxxx.json    # Results file
├── _SUCCESS                  # Success marker
└── .part-00000-xxxxx.json.crc  # Checksum
```

### JSONL Format

Each line is a complete JSON object for one PDF:

```json
{
  "document_path": "/path/to/document.pdf",
  "success": true,
  "content": "# Document Title\n\nExtracted text content...",
  "metadata": {
    "file_name": "document.pdf",
    "file_size": "1234567",
    "file_extension": ".pdf",
    "file_path": "/path/to/document.pdf",
    "num_pages": "19",
    "confidence_score": "0.95"
  },
  "error_message": null
}
```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. "Java Runtime not found"

**Error Message:**
```
Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
```

**Solution:**
```bash
# macOS
brew install openjdk@11
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# Ubuntu/Debian
sudo apt-get install openjdk-11-jdk

# Verify
java -version
```

---

#### 2. "ModuleNotFoundError: No module named 'docling_module'"

**Status:** ✅ **FIXED** (auto-handled in code)

**How it's fixed:**
The code automatically packages `docling_module` as a zip file and distributes it to workers (lines 117-144 in `run_spark_job.py`).

**Verify it's working:**
Look for this in the output:
```
   Packaged: docling_module/__init__.py
   Packaged: docling_module/processor.py
   ✅ Added docling_module package to Spark workers
```

## 🏗️ Architecture Deep Dive

### Project Structure

```
Docling-Spark-Distributed-Structuring/
├── scripts/
│   ├── docling_module/           # Core processing logic
│   │   ├── __init__.py           # Simple API: docling_process()
│   │   └── processor.py          # Docling processor with OOP design
│   └── run_spark_job.py          # Main Spark orchestration
│
├── assets/                        # Sample PDFs
│   ├── 2206.01062.pdf
│   ├── 2203.01017v2.pdf
│   └── 2305.03393v1.pdf
│
├── output/                        # Processing results
│   └── results.jsonl/            # JSONL output files
│
├── requirements.txt               # Python dependencies
└── README.md                      # This file
```

### Component Details

#### 1. **docling_module/processor.py**

**Purpose:** Core PDF processing logic using Docling

**Key Classes:**
- `DocumentConfig`: Configuration dataclass
- `ProcessingResult`: Result container
- `DoclingPDFProcessor`: Main processor class
- `DocumentProcessorFactory`: Factory for creating processors

**Key Method:**
```python
def process(self, file_path: str) -> ProcessingResult:
    """Process a PDF and return structured result."""
    # 1. Validate file
    # 2. Convert using Docling
    # 3. Extract metadata
    # 4. Return ProcessingResult
```

---

#### 2. **docling_module/__init__.py**

**Purpose:** Simplified API for Spark workers

```python
def docling_process(file_path: str) -> ProcessingResult:
    """Simple function that workers can call."""
    processor = DocumentProcessorFactory.create_processor_with_defaults()
    return processor.process(file_path)
```

---

#### 3. **run_spark_job.py**

**Purpose:** Spark orchestration and workflow

**Key Functions:**

```python
def create_spark():
    """Create Spark session and distribute docling_module."""
    # 1. Create SparkSession
    # 2. Package docling_module as zip
    # 3. Distribute to workers via addPyFile()
    
def process_pdf_wrapper(file_path: str) -> dict:
    """Wrapper that runs on workers."""
    from docling_module.processor import docling_process
    result = docling_process(file_path)
    return result.to_dict()

def main():
    """Main workflow."""
    # 1. Create Spark
    # 2. Discover PDFs
    # 3. Create DataFrame
    # 4. Apply UDF (process_pdf_wrapper)
    # 5. Collect results
    # 6. Save as JSONL
```

---

### How Workers Get the Code

This was the trickiest part to solve! Here's how it works:

**Problem:** Workers are separate processes that don't have access to `docling_module`.

**Solution:** Package and distribute (lines 117-144):

```python
# 1. Create temporary zip file
import zipfile
with zipfile.ZipFile(zip_path, 'w') as zipf:
    # 2. Add all .py files from docling_module/
    for file in os.walk(module_path):
        if file.endswith('.py'):
            zipf.write(file_path, arcname)

# 3. Distribute to workers
spark.sparkContext.addPyFile(zip_path)
```

**Result:** Each worker gets a copy of `docling_module` and can import it!

---

### Data Flow

```
1. Input: PDF file paths
   ↓
2. Spark DataFrame: ["document_path"]
   ↓
3. Apply UDF: process_pdf_wrapper(document_path)
   ↓
4. Worker imports: from docling_module.processor import docling_process
   ↓
5. Process PDF: result = docling_process(file_path)
   ↓
6. Return dict: result.to_dict()
   ↓
7. Collect results: DataFrame with all results
   ↓
8. Save: output/results.jsonl/
```

---

**Conclusion:** 
- Increasing threads from 2→4 gives **30% speedup** with minimal memory cost
- Increasing workers helps if processing 100+ PDFs
- Sweet spot: 4 workers × 4 threads = 16 parallel threads


## 🚀 Kubernetes Deployment (PRODUCTION READY!)

Deploy this system to Kubernetes for true distributed, scalable PDF processing. **This is now fully implemented and tested!**

### 🎯 Quick Deploy

```bash
# 1. Ensure Kubernetes is running
kubectl cluster-info

# 2. Build and push Docker image
docker build -t quay.io/YOUR_USERNAME/docling-spark:latest .
docker push quay.io/YOUR_USERNAME/docling-spark:latest

# 3. Deploy to Kubernetes
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/rbac.yaml
kubectl apply -f k8s/base/storage.yaml
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/base/service.yaml
kubectl apply -f k8s/spark-submit-job.yaml

# 4. Monitor the job
kubectl get pods -n docling-spark -w
kubectl logs -f -n docling-spark -l component=driver
```

---

### 📋 Prerequisites

#### 1. **Kubernetes Cluster**

**Option A: Docker Desktop (Local Development) ✅ RECOMMENDED**
```bash
# Install Docker Desktop
brew install --cask docker  # macOS

# Enable Kubernetes in Docker Desktop:
# 1. Open Docker Desktop
# 2. Settings → Kubernetes
# 3. Check "Enable Kubernetes"
# 4. Click "Apply & Restart"
# 5. Wait 2-3 minutes

# Verify
kubectl cluster-info
kubectl get nodes
```

**Option B: Minikube**
```bash
brew install minikube
minikube start --driver=docker --cpus=4 --memory=8192
```

**Option C: Cloud (Production)**
- AWS EKS
- Google GKE
- Azure AKS

#### 2. **Container Registry**

We use **Quay.io** (free, public repositories):

```bash
# Create account at https://quay.io
# Login
docker login quay.io
```

**Alternatives:**
- Docker Hub: `docker.io/username/image`
- GitHub Container Registry: `ghcr.io/username/image`
- AWS ECR, Google GCR, Azure ACR

#### 3. **Tools**
```bash
# Verify you have these
docker --version
kubectl version --client
```

---

### 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  KUBERNETES CLUSTER (Docker Desktop / Cloud)                │
│                                                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │  NAMESPACE: docling-spark                          │     │
│  │                                                    │     │
│  │  ┌──────────────────────────────────────────────┐  │     │
│  │  │  SPARK DRIVER POD                            │  │     │
│  │  │  - Image: quay.io/username/docling-spark     │  │     │
│  │  │  - Orchestrates job                          │  │     │
│  │  │  - Creates executor pods                     │  │     │
│  │  └──────────────────────────────────────────────┘  │     │
│  │                       │                            │     │
│  │         ┌─────────────┼──────────────┬─────────┐   │     │
│  │         ▼             ▼              ▼         ▼   │     │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───┐   │     │
│  │  │Executor 1│  │Executor 2│  │Executor 3│  │...│   │     │
│  │  │          │  │          │  │          │  │   │   │     │
│  │  │Docling   │  │Docling   │  │Docling   │  │   │   │     │
│  │  │Process   │  │Process   │  │Process   │  │   │   │     │
│  │  │PDF A     │  │PDF B     │  │PDF C     │  │   │   │     │
│  │  └──────────┘  └──────────┘  └──────────┘  └───┘   │     │
│  │                                                    │     │
│  │  ┌──────────────────────────────────────────────┐  │     │
│  │  │  PERSISTENT STORAGE                          │  │     │
│  │  │  - Input PVC (PDFs)                          │  │     │
│  │  │  - Output PVC (Results)                      │  │     │
│  │  └──────────────────────────────────────────────┘  │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### 🐳 Kubernetes Components

```
k8s/
├── base/
│   ├── namespace.yaml       # Isolated namespace
│   ├── rbac.yaml           # Permissions for Spark
│   ├── storage.yaml        # PVCs for input/output
│   ├── configmap.yaml      # Spark configuration
│   ├── service.yaml        # Spark UI service
│   └── secrets.yaml        # Image pull secrets
├── spark-submit-job.yaml   # Main Spark job definition
└── deploy.sh              # Automated deployment script
```

---

### 📦 Step 1: Build Docker Image

#### Dockerfile Overview

```dockerfile
FROM apache/spark-py:v3.5.0
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tesseract-ocr poppler-utils

# Install Python dependencies
COPY requirements-docker.txt .
RUN pip install -r requirements-docker.txt

# Copy application code
COPY scripts/ /app/scripts/
COPY assets/ /app/assets/

# Create spark user
RUN useradd -m -u 185 -s /bin/bash spark
ENV HOME=/home/spark
USER spark

ENTRYPOINT ["/opt/spark/bin/spark-submit"]
```

#### Build and Push

```bash
# 1. Navigate to project root
cd /path/to/Docling-Spark-Distributed-Structuring

# 2. Build the image
docker build -t quay.io/YOUR_USERNAME/docling-spark:latest .

# Expected output:
# [+] Building 300.5s (15/15) FINISHED
# => exporting to image
# => naming to quay.io/YOUR_USERNAME/docling-spark:latest

# 3. Login to Quay.io
docker login quay.io
# Username: YOUR_USERNAME
# Password: YOUR_PASSWORD

# 4. Push to registry
docker push quay.io/YOUR_USERNAME/docling-spark:latest

# Expected output:
# The push refers to repository [quay.io/YOUR_USERNAME/docling-spark]
# latest: digest: sha256:... size: 856

# 5. Make repository public (on Quay.io website)
# Go to: https://quay.io/repository/YOUR_USERNAME/docling-spark
# Settings → Repository Visibility → Public
```

**Image Size:** ~1.5 GB compressed, ~5 GB uncompressed

---

### ☸️ Step 2: Deploy to Kubernetes

#### Manual Deployment (Step-by-Step)

```bash
# 1. Create namespace
kubectl apply -f k8s/base/namespace.yaml
# Output: namespace/docling-spark created

# 2. Create RBAC (ServiceAccount, Role, RoleBinding)
kubectl apply -f k8s/base/rbac.yaml
# Output: serviceaccount/spark-driver created
#         role.rbac.authorization.k8s.io/spark-role created
#         rolebinding.rbac.authorization.k8s.io/spark-role-binding created

# 3. Create storage (PersistentVolumeClaims)
kubectl apply -f k8s/base/storage.yaml
# Output: persistentvolumeclaim/docling-input-pvc created
#         persistentvolumeclaim/docling-output-pvc created

# 4. Verify storage is bound
kubectl get pvc -n docling-spark
# NAME                 STATUS   VOLUME                                     CAPACITY
# docling-input-pvc    Bound    pvc-xxx...                                10Gi
# docling-output-pvc   Bound    pvc-yyy...                                20Gi

# 5. Create ConfigMap
kubectl apply -f k8s/base/configmap.yaml
# Output: configmap/spark-config created

# 6. Create Service (for Spark UI)
kubectl apply -f k8s/base/service.yaml
# Output: service/spark-ui created

# 7. Update image name in job manifest (if needed)
# Edit k8s/spark-submit-job.yaml lines 24 and 40:
# image: quay.io/YOUR_USERNAME/docling-spark:latest

# 8. Submit the Spark job
kubectl apply -f k8s/spark-submit-job.yaml
# Output: job.batch/docling-spark-job created
```

#### Automated Deployment

```bash
# Use the deployment script
./k8s/deploy.sh

# The script will:
# 1. Create all resources in order
# 2. Wait for storage to be ready
# 3. Submit the Spark job
# 4. Show you monitoring commands
```

---

### 📊 Step 3: Monitor the Job

#### Watch Pods

```bash
# Watch all pods in real-time
kubectl get pods -n docling-spark -w

# Expected output:
# NAME                      READY   STATUS    RESTARTS   AGE
# docling-spark-job-xxxxx   1/1     Running   0          10s
```

#### Check Job Status

```bash
# View job status
kubectl get jobs -n docling-spark

# Expected output:
# NAME                STATUS     COMPLETIONS   DURATION   AGE
# docling-spark-job   Complete   1/1           6m37s      11m
```

#### View Logs

```bash
# Follow driver logs (most useful!)
kubectl logs -f -n docling-spark -l component=driver

# Expected output:
# ✅ Spark session created with 4 workers
# 📂 Step 1: Getting list of PDF files...
# 🔄 Step 3: Processing files...
# ✅ Step 5: Results are ready!
# 💾 Step 6: Saving results...
# 🎉 ALL DONE!

# View specific pod logs
kubectl logs -n docling-spark docling-spark-job-xxxxx

# View executor logs
kubectl logs -n docling-spark -l spark-role=executor
```

#### Access Spark UI

```bash
# Port-forward Spark UI
kubectl port-forward -n docling-spark svc/spark-ui 4040:4040

# Open in browser:
# http://localhost:4040
```

---

### 📥 Step 4: Upload PDFs (Before Running Job)

```bash
# Create a temporary pod to access storage
kubectl run -it --rm upload-pod \
  --image=busybox \
  --namespace=docling-spark \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "upload",
        "image": "busybox",
        "command": ["sh"],
        "volumeMounts": [{
          "name": "input",
          "mountPath": "/data"
        }]
      }],
      "volumes": [{
        "name": "input",
        "persistentVolumeClaim": {
          "claimName": "docling-input-pvc"
        }
      }]
    }
  }'

# In another terminal, copy PDFs
kubectl cp assets/2206.01062.pdf docling-spark/upload-pod:/data/

# Or use the helper script
./k8s/upload-pdfs.sh
```

---

### 📤 Step 5: Retrieve Results

```bash
# Create a results viewer pod
kubectl run -it --rm results-viewer \
  --image=busybox \
  --namespace=docling-spark \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "viewer",
        "image": "busybox",
        "command": ["sh", "-c", "find /output -type f && sleep 3600"],
        "volumeMounts": [{
          "name": "output",
          "mountPath": "/output"
        }]
      }],
      "volumes": [{
        "name": "output",
        "persistentVolumeClaim": {
          "claimName": "docling-output-pvc"
        }
      }]
    }
  }'

# View results
kubectl exec -n docling-spark results-viewer -- cat /output/results.jsonl/part-00000-*.json

# Or use the helper script
./k8s/get-results.sh
```

#### Sample Output

```json
{
  "document_path": "/app/input/2206.01062.pdf",
  "success": true,
  "content": "## DocLayNet: A Large Human-Annotated Dataset for Document Layout Analysis\n\n...",
  "metadata": {
    "file_path": "/app/input/2206.01062.pdf",
    "file_name": "2206.01062.pdf",
    "confidence_score": "0.9639551330888779",
    "num_pages": "19",
    "file_extension": ".pdf",
    "file_size": "4310680"
  },
  "error_message": null
}
```

---

### 🔄 Processing Flow on Kubernetes

```
1. User submits job
   ↓
2. Driver pod starts
   ↓
3. Driver creates executor pods (dynamic allocation)
   ↓
4. Driver reads PDF list from input PVC
   ↓
5. PDFs distributed to executors
   ↓
6. Each executor:
   - Loads Docling module
   - Processes assigned PDFs
   - Extracts text + metadata
   ↓
7. Results collected by driver
   ↓
8. Results written to output PVC
   ↓
9. Job completes (pods terminate)
   ↓
10. User retrieves results from PVC
```

---

### ⚙️ Configuration

#### Resource Limits

Edit `k8s/spark-submit-job.yaml`:

```yaml
# Driver resources
resources:
  requests:
    memory: "4Gi"
    cpu: "2"
  limits:
    memory: "6Gi"
    cpu: "3"

# Executor configuration
- --conf
- spark.executor.instances=5      # Number of executors
- --conf
- spark.executor.memory=4g        # RAM per executor
- --conf
- spark.executor.cores=2          # CPUs per executor
```

#### Storage Size

Edit `k8s/base/storage.yaml`:

```yaml
# Input storage
resources:
  requests:
    storage: 10Gi    # Increase if you have many PDFs

# Output storage
resources:
  requests:
    storage: 20Gi    # Increase if processing large volumes
```

---

### 🧹 Cleanup

```bash
# Delete the job
kubectl delete job docling-spark-job -n docling-spark

# Delete all resources
kubectl delete namespace docling-spark

# Or delete individual components
kubectl delete -f k8s/spark-submit-job.yaml
kubectl delete -f k8s/base/service.yaml
kubectl delete -f k8s/base/configmap.yaml
kubectl delete -f k8s/base/storage.yaml
kubectl delete -f k8s/base/rbac.yaml
kubectl delete -f k8s/base/namespace.yaml
```