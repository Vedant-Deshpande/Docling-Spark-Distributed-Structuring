# Docling-Spark-Distributed-Structuring
Use Docling to turn unstructured PDFs into structured JSON. A custom UDF applies this conversion to every document. PySpark runs that UDF in parallel across many workers to handle millions of files efficiently. Kubernetes/OpenShift manages the Spark cluster automatically using the Spark Operator.
