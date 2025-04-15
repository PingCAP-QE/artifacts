# Docker-in-Docker (DinD) Builder Pod for Multi-Arch Images with Skaffold

This directory contains a Kubernetes pod definition for building multi-architecture container images using Skaffold with Docker-in-Docker (DinD) mode.

## Prerequisites

- A Kubernetes cluster with:
  - Sufficient privileges to create privileged containers
- `kubectl` configured to access your cluster

## Usage

### 1. Apply the Pod Definition

```bash
kubectl apply -f dind-builder-pod.yaml
```

### 2. Wait for the Pod to be Ready

```bash
kubectl wait --for=condition=Ready pod/dind-skaffold-builder
```

### 3. Execute Skaffold Commands

Connect to the Skaffold container:

```bash
kubectl exec -it dind-skaffold-builder -c skaffold -- bash
```

### 4. Building Multi-Arch Images

Once inside the container, you can use Skaffold to build multi-architecture images:

```bash
# Navigate to your project directory
cd /workspace/your-project

# Run Skaffold build with platform support
skaffold build --platform=linux/amd64,linux/arm64
```

## Example Workflow

1. Copy your source code to the pod:

```bash
kubectl cp ./your-source-code dind-skaffold-builder:/workspace/your-project -c skaffold
```

2. Enter the pod and build images:

```bash
kubectl exec -it dind-skaffold-builder -c skaffold -- bash
cd /workspace/your-project
skaffold build --platform=linux/amd64,linux/arm64 --push
```

## Cleaning Up

When you're done building, delete the pod:

```bash
kubectl delete -f dind-builder-pod.yaml
```

## Notes

- The pod uses privileged mode for the Docker container, which has security implications
- Adjust the resource requests/limits in the YAML according to your build requirements
- For persistent storage, replace the `emptyDir` volumes with appropriate persistent volumes
