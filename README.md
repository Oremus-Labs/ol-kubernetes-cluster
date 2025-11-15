# Oremus-Labs Kubernetes Configuration

This repository codifies the full state of the Oremus-Labs management cluster by using Argo CD's App-of-Apps model. Everything that runs on the cluster starts here and is deployed by Argo CD via Helm.

## Layout

- `clusters/oremus-labs/mgmt/bootstrap/` – the only manifest that must be applied manually. It creates the root Argo CD `Application` that points back into this repo.
- `clusters/oremus-labs/mgmt/root/` – Argo CD synchronizes this path. It defines projects and the ApplicationSets that orchestrate platform/workload components.
- `apps/` – Helm value overlays for every component managed by Argo CD (platform or workload).

## Managed components

- Argo CD (platform GitOps control plane) – Helm chart `argo-cd` pinned at `5.34.3`.
- Kube-VIP (control-plane virtual IP / load-balancer) – Helm chart `kube-vip` pinned at `0.9.1`.
- MetalLB (in-cluster load balancer) – Helm chart `metallb` pinned at `0.14.5`.
- Metrics Server (resource usage API) – Helm chart `metrics-server` pinned at `3.12.1`.
- CoreDNS (cluster DNS) – declarative manifests mirroring the kubeadm defaults (image `coredns/coredns:1.12.1`).

## Bootstrap

```bash
kubectl apply -f clusters/oremus-labs/mgmt/bootstrap/root-application.yaml
```

Once the root application finishes syncing, the management cluster will be fully in sync with the declarations in this repository.
