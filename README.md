# Install RHAIIS (Red Hat AI Inference Server) on OCP/K8s

> **⚠️ DISCLAIMER: Community Project**
> 
> This is **NOT an official Red Hat product or project**. This is a community-driven project intended **for experimentation and learning purposes only** with Red Hat AI Inference Server (RHAIIS).
> 
> **For official setup, implementation, and production deployments**, please refer to the official Red Hat documentation:
> 📖 [Red Hat AI Inference Server Official Documentation](https://docs.redhat.com/en/documentation/red_hat_ai_inference_server/3.2/html/deploying_red_hat_ai_inference_server_in_openshift_container_platform/index)
> 
> **Use this project at your own risk** and ensure compliance with your organization's policies and Red Hat's licensing terms.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.x-red.svg)](https://www.redhat.com/en/technologies/cloud-computing/openshift)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.19+-blue.svg)](https://kubernetes.io/)
[![Community](https://img.shields.io/badge/Community-Experimental-orange.svg)](https://github.com/micytao/rhaiis)

A comprehensive deployment solution for Red Hat AI Inference Server (RHAIIS) that provides an OpenAI-compatible API server powered by vLLM for serving large language models with GPU acceleration.

## 🚀 Features

- **OpenAI-Compatible API**: Drop-in replacement for OpenAI API endpoints
- **GPU Acceleration**: Optimized for NVIDIA GPUs with vLLM backend
- **Multiple Deployment Options**: Helm charts and Kustomize configurations
- **Production Ready**: Comprehensive security, monitoring, and scaling features
- **Multi-Environment Support**: Development, staging, and production configurations
- **Operator Integration**: Automated GPU and Node Feature Discovery setup

## 📋 Prerequisites

### Infrastructure Requirements
- **Kubernetes 1.19+** or **OpenShift 4.x**
- **GPU nodes** with NVIDIA GPUs
- **Persistent storage** (50Gi+ recommended for model cache)
- **Network access** to `registry.redhat.io` and `huggingface.co`

### Access Requirements
- **Red Hat Registry Access**: Valid credentials for `registry.redhat.io`
- **Hugging Face Token**: For model downloads ([Get token here](https://huggingface.co/settings/tokens))
- **Cluster Admin Privileges**: For operator installation (if using Kustomize)

### Software Requirements
- **Helm 3.2.0+** (for Helm deployment)
- **Kustomize** (included with kubectl 1.14+)
- **OpenShift CLI** or **kubectl**

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    RHAIIS Architecture                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────┐    │
│  │   Client    │───▶│ OpenShift    │───▶│   RHAIIS    │    │
│  │ Application │    │   Route      │    │    Pod      │    │
│  └─────────────┘    └──────────────┘    └─────────────┘    │
│                                               │             │
│  ┌─────────────────────────────────────────────┼─────────┐  │
│  │              GPU Infrastructure             │         │  │
│  │  ┌─────────────┐    ┌─────────────────┐    │         │  │
│  │  │     NFD     │    │  GPU Operator   │    ▼         │  │
│  │  │  (Node      │    │  (GPU Resource  │ ┌─────────┐  │  │
│  │  │ Discovery)  │    │   Management)   │ │  vLLM   │  │  │
│  │  └─────────────┘    └─────────────────┘ │ Engine  │  │  │
│  └─────────────────────────────────────────┴─────────┴──┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                Storage Layer                        │   │
│  │  ┌─────────────┐         ┌─────────────────────┐    │   │
│  │  │ Model Cache │         │   Application Cache │    │   │
│  │  │   (20Gi)    │         │       (50Gi)        │    │   │
│  │  └─────────────┘         └─────────────────────┘    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Option 1: Kustomize Deployment (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/micytao/rhaiis.git
cd rhaiis

# 2. Deploy operators first
kubectl apply -k kustomize/overlays/operators/install/

# 3. Wait for operators to be ready
kubectl wait --for=condition=Succeeded csv -n openshift-nfd --all --timeout=300s
kubectl wait --for=condition=Succeeded csv -n nvidia-gpu-operator --all --timeout=300s

# 4. Create operator instances
kubectl apply -k kustomize/overlays/operators/instances/

# 5. Deploy application
kubectl apply -k kustomize/overlays/app/
```

### Option 2: Helm Deployment

```bash
# 1. Clone the repository
git clone https://github.com/micytao/rhaiis.git
cd rhaiis

# 2. Create namespace and secrets
kubectl create namespace rhaiis
kubectl create secret docker-registry docker-secret \
  --docker-server=registry.redhat.io \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --namespace=rhaiis

# 3. Install with Helm
helm install rhaiis ./rhaiis-helm-chart \
  --namespace rhaiis \
  --set secrets.huggingface.token="your-hf-token-here"
```

## 📁 Project Structure

```
rhaiis/
├── README.md                    # This file
├── SETUP.md                     # Detailed setup instructions
├── .gitignore                   # Git ignore rules (includes security exclusions)
│
├── kustomize/                  # 🎯 Kustomize Deployment (Recommended)
│   ├── README.md               # Kustomize-specific documentation
│   ├── base/                   # Base Kubernetes resources
│   └── overlays/               # Environment-specific configurations
│       ├── operators/          # GPU and NFD operator setup
│       ├── dev/                # Development environment
│       ├── prod/               # Production environment
│       └── app/                # Application overlay
│
├── rhaiis-helm-chart/          # 🔧 Helm Chart
│   ├── Chart.yaml              # Chart metadata
│   ├── README.md               # Helm-specific documentation
│   ├── INSTALL.md              # Quick installation guide
│   ├── values.yaml             # Default configuration
│   ├── values-local.yaml.template  # Template for local development
│   └── templates/              # Kubernetes manifests
│       ├── deployment.yaml     # Main application deployment
│       ├── service.yaml        # Service definition
│       ├── route.yaml          # OpenShift route
│       ├── secret.yaml         # Secret management
│       └── pvc-*.yaml          # Persistent volume claims
│
└── *.yml                       # 📄 Standalone manifests (legacy)
```

## 🔧 Configuration Options

### Deployment Methods Comparison

| Feature | Kustomize | Helm Chart | Standalone |
|---------|-----------|------------|------------|
| **Ease of Use** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Customization** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Environment Management** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐ |
| **Operator Integration** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ |
| **Production Ready** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **GitOps Friendly** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

### Key Configuration Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `app.model` | Hugging Face model to serve | `RedHatAI/Llama-3.2-1B-Instruct-FP8` | ✅ |
| `secrets.huggingface.token` | HF token for model access | `<placeholder>` | ✅ |
| `resources.limits.gpu` | GPU resource limit | `1` | ✅ |
| `storage.cache.size` | Application cache size | `50Gi` | ✅ |
| `storage.modelCache.size` | Model cache size | `20Gi` | ✅ |

## 🔐 Security Best Practices

### Token Management

⚠️ **CRITICAL**: Never commit actual tokens to git!

This project implements multiple secure token handling methods:

1. **Command Line Injection** (Testing)
   ```bash
   helm install rhaiis ./rhaiis-helm-chart \
     --set secrets.huggingface.token="your-token"
   ```

2. **Local Values File** (Development)
   ```bash
   # Copy template and add your token
   cp rhaiis-helm-chart/values-local.yaml.template rhaiis-helm-chart/values-local.yaml
   # Edit values-local.yaml with your actual token (git-ignored)
   
   helm install rhaiis ./rhaiis-helm-chart \
     --values ./rhaiis-helm-chart/values-local.yaml
   ```

3. **External Secrets** (Production)
   ```bash
   # Create secret manually
   kubectl create secret generic my-hf-secret \
     --from-literal=HF_TOKEN="your-token" \
     --namespace rhaiis
   
   # Reference in deployment
   helm install rhaiis ./rhaiis-helm-chart \
     --set secrets.huggingface.existingSecret.name="my-hf-secret"
   ```

### Security Features

- ✅ **Git-ignored sensitive files** (`values-local.yaml`, `hf_token.txt`)
- ✅ **Non-root container execution**
- ✅ **Security contexts** with dropped capabilities
- ✅ **Network policies** (configurable)
- ✅ **RBAC** with minimal permissions
- ✅ **TLS termination** at route level

## 🌍 Environment-Specific Deployments

### Development Environment (Kustomize - Recommended)
```bash
# Lower resource requirements, single replica
kubectl apply -k kustomize/overlays/dev/
```

### Production Environment (Kustomize - Recommended)
```bash
# High availability, multiple replicas, production settings
kubectl apply -k kustomize/overlays/prod/
```

### Alternative: Helm Deployments

#### Development Environment
```bash
# Lower resource requirements, single replica
helm install rhaiis-dev ./rhaiis-helm-chart \
  --namespace rhaiis-dev \
  --values ./rhaiis-helm-chart/values-local.yaml \
  --set replicaCount=1 \
  --set resources.limits.cpu="4" \
  --set resources.limits.memory="8Gi"
```

#### Production Environment
```bash
# High availability, multiple replicas
helm install rhaiis-prod ./rhaiis-helm-chart \
  --namespace rhaiis-prod \
  --set replicaCount=3 \
  --set resources.limits.cpu="16" \
  --set resources.limits.memory="32Gi" \
  --set secrets.huggingface.existingSecret.name="prod-hf-secret"
```

## 📊 Monitoring and Observability

### Health Checks
- **Readiness Probe**: `/health` endpoint (30s delay, 10s interval)
- **Liveness Probe**: `/health` endpoint (60s delay, 30s interval)

### Metrics and Logging
- **Application Logs**: Available via `kubectl logs`
- **GPU Metrics**: Exposed via NVIDIA GPU Operator
- **Custom Metrics**: vLLM performance metrics (configurable)

### Verification Commands
```bash
# Check deployment status
kubectl get pods -n rhaiis
kubectl get routes -n rhaiis  # OpenShift
kubectl get ingress -n rhaiis # Kubernetes

# Test API endpoint
curl https://$(kubectl get route rhaiis-route -n rhaiis -o jsonpath='{.spec.host}')/health

# Check GPU allocation
kubectl describe node <gpu-node> | grep nvidia.com/gpu
```

## 🔄 Scaling and Performance

### Horizontal Scaling
```bash
# Scale replicas
kubectl scale deployment rhaiis -n rhaiis --replicas=3

# Or via Helm upgrade
helm upgrade rhaiis ./rhaiis-helm-chart \
  --set replicaCount=3
```

### Vertical Scaling
```bash
# Increase resources
helm upgrade rhaiis ./rhaiis-helm-chart \
  --set resources.limits.cpu="32" \
  --set resources.limits.memory="64Gi" \
  --set resources.limits.nvidia.com/gpu="2"
```

### Performance Tuning
- **Model Parallelism**: Set `app.tensorParallelSize` for multi-GPU models
- **Cache Optimization**: Increase `storage.cache.size` for better performance
- **Memory Management**: Adjust `storage.sharedMemory.sizeLimit` for large models

## 🛠️ Troubleshooting

### Common Issues

#### 1. GPU Not Available
```bash
# Check GPU operator status
kubectl get pods -n nvidia-gpu-operator
kubectl get clusterpolicy

# Verify GPU nodes
kubectl get nodes -l nvidia.com/gpu.present=true
```

#### 2. Model Download Failures
```bash
# Check HF token
kubectl get secret hf-secret -n rhaiis -o yaml

# Check network connectivity
kubectl exec -it <pod-name> -n rhaiis -- curl -I https://huggingface.co
```

#### 3. Pod Startup Issues
```bash
# Check pod events
kubectl describe pod <pod-name> -n rhaiis

# Check logs
kubectl logs <pod-name> -n rhaiis --previous
```

### Debug Mode
```bash
# Enable debug logging
helm upgrade rhaiis ./rhaiis-helm-chart \
  --set env.VLLM_LOG_LEVEL="DEBUG"
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup
```bash
# Clone your fork
git clone https://github.com/your-username/rhaiis.git
cd rhaiis

# Create local values file
cp rhaiis-helm-chart/values-local.yaml.template rhaiis-helm-chart/values-local.yaml
# Edit with your tokens and preferences

# Test deployment
helm install rhaiis-dev ./rhaiis-helm-chart \
  --namespace rhaiis-dev \
  --values ./rhaiis-helm-chart/values-local.yaml \
  --dry-run --debug
```

## 📚 Documentation

### Official Red Hat Documentation
- **[Red Hat AI Inference Server Official Documentation](https://docs.redhat.com/en/documentation/red_hat_ai_inference_server/3.2/html/deploying_red_hat_ai_inference_server_in_openshift_container_platform/index)** - Official Red Hat deployment guide

### Community Project Documentation
- **[Helm Chart Documentation](./rhaiis-helm-chart/README.md)** - Detailed Helm configuration
- **[Kustomize Documentation](./kustomize/README.md)** - Kustomize deployment guide
- **[Installation Guide](./rhaiis-helm-chart/INSTALL.md)** - Quick installation steps
- **[Setup Instructions](./SETUP.md)** - Security and token configuration

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/micytao/rhaiis/issues)
- **Discussions**: [GitHub Discussions](https://github.com/micytao/rhaiis/discussions)
- **Documentation**: [Project Wiki](https://github.com/micytao/rhaiis/wiki)

## 🏷️ Tags

`#AI` `#LLM` `#vLLM` `#OpenShift` `#Kubernetes` `#GPU` `#RedHat` `#Helm` `#Kustomize` `#MLOps`

---

**Made with ❤️ for the AI/ML community**
