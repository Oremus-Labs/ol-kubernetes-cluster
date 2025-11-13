# cert-manager base

This base intentionally does not vendor the Helm chart. The ApplicationSet uses the official Jetstack Helm repo.
Add custom ClusterIssuer or Certificate manifests in overlays only.
