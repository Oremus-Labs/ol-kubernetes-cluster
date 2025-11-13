# New GitOps Structure (Multi-Cluster / Provider-Aware)

This scaffold introduces an industry-standard Argo CD + ApplicationSet layout supporting on-prem and cloud clusters via cluster labels.

## Key Concepts
- ApplicationSets fan out platform + workload apps to every matching cluster.
- Cluster labels drive targeting: `provider=onprem|cloud`; currently only production clusters are in use (optional future label: `env=prod`).
- Platform vs workloads isolation with separate AppProjects.
- On-prem only components: kube-vip (excluded from cloud by label selector).
- Helm charts consumed directly (traefik, cert-manager) to avoid vendoring.
- Kustomize overlays for provider or environment-specific differences (kube-vip IP ranges, 1Password env overlays, etc.).

## Bootstrap Flow
1. Install Argo CD (namespace `argocd`) since the live cluster currently has no Argo CD:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
   (Optional) Replace with a pinned Helm install if preferred.
2. (Wait for `argocd-server` pod Ready) Then apply the bootstrap bundle:
   ```bash
   kubectl apply -k bootstrap/
   ```
3. Label cluster secret in `argocd` so selectors match (example on-prem dev):
   ```bash
   kubectl get secrets -n argocd | grep cluster- # identify secret name
   kubectl label secret -n argocd <cluster-secret-name> provider=onprem env=dev --overwrite
   ```
4. ApplicationSets reconcile and create component Applications; namespaces will be auto-created due to `CreateNamespace=true`.
5. (Later) Add additional cluster secrets with provider/cloud labels for fan-out.

## Next Steps / TODO
- (Completed) Legacy `registry/projects/development` tree removed; all manifests now live under `apps/` + `appsets/`.
- Externalize secrets (Traefik dashboard auth, 1Password session) using External Secrets + 1Password Connect (replace placeholder `OP_SESSION`).
- Add additional workloads by creating new directories under `apps/workloads/<app>/` and an ApplicationSet entry if needed.
- Add cloud-specific components (external-dns, CSI drivers, metrics/observability) under `apps/platform/<component>/` with overlays + ApplicationSets.
- Add a Certificate / ClusterIssuer set (e.g., `apps/platform/cert-manager/overlays/onprem/cluster-issuers.yaml`) to back `wildcard-oremuslabs-app-tls`.

## Safety / Migration Strategy
Run new structure in parallel initially (both old and new). Once validated, remove the legacy root application and its children.

## Notes
This is a starter scaffold; refine resource whitelists, RBAC, sync waves, and add health checks as you harden production.
