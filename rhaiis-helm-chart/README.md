# RHAIIS Helm Chart

A Helm chart for deploying Red Hat AI Infrastructure Services (RHAIIS) with vLLM on Kubernetes/OpenShift.

## Overview

This Helm chart deploys RHAIIS, which provides an OpenAI-compatible API server powered by vLLM for serving large language models with GPU acceleration.

## Prerequisites

- Kubernetes 1.19+ or OpenShift 4.x
- Helm 3.2.0+
- GPU nodes with NVIDIA GPU Operator installed
- Access to Red Hat container registry (`registry.redhat.io`)
- Hugging Face token for model access

## Installation

### Add Required Secrets

First, create the Docker registry secret for accessing Red Hat images:

```bash
kubectl create secret docker-registry docker-secret \
  --docker-server=registry.redhat.io \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --namespace=rhaiis
```

### Install the Chart

```bash
# Create namespace
kubectl create namespace rhaiis

# Install the chart
helm install rhaiis ./rhaiis-helm-chart \
  --namespace rhaiis \
  --set secrets.huggingface.token="your-hf-token-here"
```

### Install with Custom Values

```bash
helm install rhaiis ./rhaiis-helm-chart \
  --namespace rhaiis \
  --values custom-values.yaml
```

## Configuration

The following table lists the configurable parameters and their default values:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Namespace to deploy resources | `rhaiis` |
| `image.repository` | Container image repository | `registry.redhat.io/rhaiis/vllm-cuda-rhel9` |
| `image.tag` | Container image tag | `3.2.1` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas | `1` |
| `app.model` | Model to serve | `RedHatAI/Llama-3.2-1B-Instruct-FP8` |
| `app.port` | Application port | `8000` |
| `secrets.huggingface.token` | Hugging Face API token | `""` |
| `storage.cache.size` | Cache storage size | `50Gi` |
| `storage.modelCache.size` | Model cache storage size | `20Gi` |
| `resources.limits.cpu` | CPU limit | `16` |
| `resources.limits.memory` | Memory limit | `32Gi` |
| `resources.limits["nvidia.com/gpu"]` | GPU limit | `1` |
| `route.enabled` | Enable OpenShift Route | `true` |

## Usage Examples

### Basic Installation

```bash
helm install rhaiis ./rhaiis-helm-chart \
  --namespace rhaiis \
  --create-namespace \
  --set secrets.huggingface.token="hf_your_token_here"
```

### Custom Model and Resources

```bash
helm install rhaiis ./rhaiis-helm-chart \
  --namespace rhaiis \
  --set app.model="microsoft/DialoGPT-large" \
  --set resources.limits.memory="64Gi" \
  --set resources.limits.cpu="32" \
  --set storage.cache.size="100Gi"
```

### Production Configuration

Create a `production-values.yaml` file:

```yaml
replicaCount: 2

resources:
  limits:
    cpu: "32"
    memory: "64Gi"
    nvidia.com/gpu: "2"
  requests:
    cpu: "8"
    memory: "16Gi"
    nvidia.com/gpu: "2"

storage:
  cache:
    size: 200Gi
    storageClassName: fast-ssd
  modelCache:
    size: 100Gi
    storageClassName: fast-ssd

app:
  tensorParallelSize: 2
  model: "microsoft/DialoGPT-large"

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: accelerator
          operator: In
          values:
          - nvidia-tesla-v100
          - nvidia-tesla-a100

tolerations:
  - key: "nvidia.com/gpu"
    operator: "Exists"
    effect: "NoSchedule"
```

Install with production values:

```bash
helm install rhaiis ./rhaiis-helm-chart \
  --namespace rhaiis \
  --values production-values.yaml
```

## Accessing the Service

### Via OpenShift Route (Default)

If running on OpenShift with `route.enabled=true`, the service will be accessible via the generated route:

```bash
# Get the route URL
oc get route rhaiis-route -n rhaiis -o jsonpath='{.spec.host}'

# Test the API
curl -X POST "https://$(oc get route rhaiis-route -n rhaiis -o jsonpath='{.spec.host}')/v1/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "RedHatAI/Llama-3.2-1B-Instruct-FP8",
    "prompt": "Hello, world!",
    "max_tokens": 50
  }'
```

### Via Port Forward

```bash
kubectl port-forward svc/rhaiis-service 8000:8000 -n rhaiis
curl -X POST "http://localhost:8000/v1/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "RedHatAI/Llama-3.2-1B-Instruct-FP8",
    "prompt": "Hello, world!",
    "max_tokens": 50
  }'
```

## Monitoring

Check deployment status:

```bash
# Check pods
kubectl get pods -n rhaiis

# Check logs
kubectl logs -f deployment/rhaiis -n rhaiis

# Check service
kubectl get svc -n rhaiis

# Check route (OpenShift)
oc get route -n rhaiis
```

## Troubleshooting

### Common Issues

1. **Pod stuck in Pending**: Check if GPU nodes are available and properly labeled
2. **ImagePullBackOff**: Ensure docker-secret is created and valid
3. **Model download failures**: Verify Hugging Face token has access to the model
4. **OOM Killed**: Increase memory limits or use smaller models

### Debug Commands

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n rhaiis

# Check resource usage
kubectl top pod -n rhaiis

# Check persistent volumes
kubectl get pv,pvc -n rhaiis

# Validate Helm release
helm status rhaiis -n rhaiis
helm get values rhaiis -n rhaiis
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade rhaiis ./rhaiis-helm-chart \
  --namespace rhaiis \
  --set image.tag="3.3.0"

# Rollback if needed
helm rollback rhaiis 1 -n rhaiis
```

## Uninstallation

```bash
# Uninstall the release
helm uninstall rhaiis -n rhaiis

# Clean up PVCs (if needed)
kubectl delete pvc -l app.kubernetes.io/name=rhaiis -n rhaiis

# Delete namespace
kubectl delete namespace rhaiis
```

## License

This chart is licensed under the Apache License 2.0.
