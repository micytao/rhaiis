# Quick Installation Guide

## Prerequisites

1. **Create namespace:**
   ```bash
   kubectl create namespace rhaiis
   ```

2. **Create Docker registry secret:**
   ```bash
   kubectl create secret docker-registry docker-secret \
     --docker-server=registry.redhat.io \
     --docker-username=<your-redhat-username> \
     --docker-password=<your-redhat-password> \
     --namespace=rhaiis
   ```

## Installation

### Option 1: Basic Installation
```bash
helm install rhaiis ./rhaiis-helm-chart \
  --namespace rhaiis \
  --set secrets.huggingface.token="your-hf-token-here"
```

### Option 2: Custom Values File
Create `my-values.yaml`:
```yaml
secrets:
  huggingface:
    token: "your-hf-token-here"

app:
  model: "microsoft/DialoGPT-large"

resources:
  limits:
    cpu: "32"
    memory: "64Gi"

storage:
  cache:
    size: 100Gi
```

Install with custom values:
```bash
helm install rhaiis ./rhaiis-helm-chart \
  --namespace rhaiis \
  --values my-values.yaml
```

## Verification

1. **Check pods:**
   ```bash
   kubectl get pods -n rhaiis
   ```

2. **Check logs:**
   ```bash
   kubectl logs -f deployment/rhaiis -n rhaiis
   ```

3. **Get route (OpenShift):**
   ```bash
   oc get route rhaiis-rhaiis-route -n rhaiis
   ```

## Test the API

```bash
# Port forward (for testing)
kubectl port-forward svc/rhaiis-rhaiis-service 8000:8000 -n rhaiis

# Test completions endpoint
curl -X POST "http://localhost:8000/v1/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "RedHatAI/Llama-3.2-1B-Instruct-FP8",
    "prompt": "Hello, world!",
    "max_tokens": 50
  }'
```

## Cleanup

```bash
# Uninstall
helm uninstall rhaiis -n rhaiis

# Delete PVCs (optional)
kubectl delete pvc -l app.kubernetes.io/name=rhaiis -n rhaiis

# Delete namespace
kubectl delete namespace rhaiis
```
