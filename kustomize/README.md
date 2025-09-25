# RHAIIS Kustomize Deployment

This directory contains Kustomize configurations for deploying Red Hat AI Infrastructure Solution (RHAIIS).

## Structure

```
kustomize/
├── base/                     # Base Kubernetes resources
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── pvc-cache.yaml
│   ├── pvc-model-cache.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── route.yaml
├── overlays/
│   ├── operators/            # Operator prerequisites (NFD, GPU)
│   │   ├── kustomization.yaml
│   │   ├── install/              # Operator installation
│   │   │   ├── kustomization.yaml
│   │   │   ├── nfd-*.yaml
│   │   │   └── gpu-*.yaml
│   │   └── instances/            # Custom resources (post-install)
│   │       ├── kustomization.yaml
│   │       ├── nfd-instance.yaml     # NodeFeatureDiscovery CR
│   │       └── gpu-clusterpolicy.yaml # GPU ClusterPolicy CR
│   ├── app/                  # Application overlay
│   │   └── kustomization.yaml
│   ├── dev/                  # Development environment
│   │   ├── kustomization.yaml
│   │   └── deployment-patch.yaml
│   └── prod/                 # Production environment
│       ├── kustomization.yaml
│       └── deployment-patch.yaml
└── kustomization.yaml        # Complete deployment
```

## Prerequisites

Before deploying RHAIIS, ensure you have:

1. **OpenShift cluster** with appropriate GPU nodes
2. **Kustomize CLI** installed (`kubectl` includes kustomize)
3. **Cluster admin privileges** for operator installation
4. **Docker secret** created in the rhaiis namespace (for image pulls)

```bash
# Create docker secret for image pulls
oc create secret docker-registry docker-secret \
  --docker-server=registry.redhat.io \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email> \
  -n rhaiis
```

## Deployment Options

### Option 1: Complete Deployment (Operators + Application)

Deploy everything at once:

```bash
kubectl apply -k kustomize/
```

### Option 2: Step-by-Step Deployment (Recommended)

#### Step 1: Install Operators

```bash
kubectl apply -k kustomize/overlays/operators/install/
```

Wait for operators to be installed and ready:

```bash
# Check NFD operator is ready
oc get csv -n openshift-nfd
oc wait --for=condition=Succeeded csv -n openshift-nfd --all --timeout=300s

# Check GPU operator is ready  
oc get csv -n nvidia-gpu-operator
oc wait --for=condition=Succeeded csv -n nvidia-gpu-operator --all --timeout=300s
```

#### Step 2: Create Operator Instances

```bash
kubectl apply -k kustomize/overlays/operators/instances/
```

Verify instances are created:

```bash
# Check NodeFeatureDiscovery instance
oc get NodeFeatureDiscovery -n openshift-nfd

# Check ClusterPolicy instance
oc get clusterpolicy gpu-cluster-policy

# Verify GPU nodes are labeled (may take a few minutes)
oc get nodes -l nvidia.com/gpu.present=true
```

#### Step 3: Deploy Application

```bash
kubectl apply -k kustomize/overlays/app/
```

### Option 3: Environment-Specific Deployments

#### Development Environment

```bash
kubectl apply -k kustomize/overlays/dev/
```

#### Production Environment

```bash
kubectl apply -k kustomize/overlays/prod/
```

## Customization

### Modifying Base Configuration

Edit files in `base/` directory to change core application settings.

### Environment-Specific Changes

- **Development**: Lower resource requirements, single replica
- **Production**: Higher resource requirements, multiple replicas

Edit `overlays/{env}/deployment-patch.yaml` to customize per environment.

### Adding New Environments

1. Create new directory under `overlays/`
2. Create `kustomization.yaml` referencing `../app`
3. Add environment-specific patches

## Verification

After deployment, verify the application:

```bash
# Check RHAIIS pods
oc get pods -n rhaiis

# Check GPU operator pods
oc get pods -n nvidia-gpu-operator

# Check NFD pods  
oc get pods -n openshift-nfd

# Check route
oc get route -n rhaiis

# Test the API
curl https://$(oc get route rhaiis-route -n rhaiis -o jsonpath='{.spec.host}')/health

# Verify GPU resources are available
oc describe node <gpu-node-name> | grep nvidia.com/gpu
```

## Cleanup

To remove the deployment:

```bash
# Remove application
kubectl delete -k kustomize/overlays/app/

# Remove operators (optional)
kubectl delete -k kustomize/overlays/operators/
```

## Troubleshooting

### CRD Not Found Errors

If you see errors like:
```
no matches for kind "NodeFeatureDiscovery" in version "nfd.kubernetes.io/v1"
no matches for kind "ClusterPolicy" in version "nvidia.com/v1"
```

This means you're trying to create custom resources before the operators are installed. Use the step-by-step deployment:

1. **First**: Install operators: `kubectl apply -k kustomize/overlays/operators/install/`
2. **Wait**: For operators to be ready (check with `oc get csv`)
3. **Then**: Create instances: `kubectl apply -k kustomize/overlays/operators/instances/`

### Operator Installation Check

```bash
# Check all operators are installed
oc get csv --all-namespaces | grep -E "(nfd|gpu-operator)"

# Check CRDs are available
oc get crd | grep -E "(nodefeaturesdiscoveries|clusterpolicies)"
```

## Security Notes

- The HuggingFace token in `secret.yaml` should be replaced with your actual token
- Consider using external secret management (e.g., External Secrets Operator)
- Review and adjust security contexts as needed for your environment
