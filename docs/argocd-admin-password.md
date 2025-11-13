# Setting Argo CD Admin Password via 1Password Connect

## TL;DR
- Keep the bcrypt hash for `admin.password` in 1Password (path `op://oremuslabs.app/argocd-admin-password/password`).
- Update `apps/platform/argocd-config/overlays/admin-password/argocd-secret-patch.yaml` with the new hash and UTC `admin.passwordMtime`.
- Let the ApplicationSet sync; Argo CD detects secret changes and refreshes the UI at `https://argocd.oremuslabs.app`.

## Background
Argo CD only stores a bcrypt hash of the admin password (`admin.password`) and a timestamp (`admin.passwordMtime`). Changing both triggers rotation without needing to restart pods, and plaintext never lives inside the cluster.

## How this repo wires it
- `appsets/platform/argocd-config.yaml` deploys the overlay under `apps/platform/argocd-config/overlays/admin-password`.
- The overlay contains `argocd-secret-patch.yaml`, which patches the `argocd-secret` with the hash and timestamp.
- `docs/onepassword-connect.md` shows how to run the Connect server and operator; the Cloudflare token used by `cert-manager` lives at `op://oremuslabs.app/cloudflare-api-token/credential`.

## Rotation workflow
1. Pick a new admin password (store it in 1Password if you need an audit trail), then generate a bcrypt hash with cost ≥ 12:
   ```bash
   argocd admin hash-password 'MyS3cureAdm1n!'
   ```
   Or use `htpasswd`:
   ```bash
   htpasswd -bnBC 12 "" 'MyS3cureAdm1n!' | tr -d ':\n' | sed 's/$2y/$2a/'
   ```
2. Update `argocd-secret-patch.yaml`:
   - Set `admin.password` to the bcrypt string stored at `op://oremuslabs.app/argocd-admin-password/password`.
   - Update `admin.passwordMtime` with `date -u +%Y-%m-%dT%H:%M:%SZ`.
3. Commit & push; the ApplicationSet applies the overlay to each cluster and keeps Argo CD in sync. The external DNS `argocd.oremuslabs.app` should resolve to your LoadBalancer/Traefik entry so the UI stays reachable.

## Optional: plaintext + PreSync hashing job
If you prefer storing only plaintext in 1Password, create a `OnePasswordItem` (or ExternalSecret) that produces a `Secret` like `argocd-admin-plaintext/password`, then add a PreSync Job that:
- hashes the plaintext with `htpasswd`,
- writes both the hash and a fresh `admin.passwordMtime` to `argocd-secret`,
- and lets Argo CD finish the sync. The job snippet below demonstrates the flow:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: argocd-admin-hash
  namespace: argocd
  annotations:
    argocd.argoproj.io/hook: PreSync
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: hasher
          image: alpine:3.20
          command: ["/bin/sh","-c"]
          args:
            - apk add --no-cache apache2-utils && \
              PW=$(cat /secrets/password) && \
              HASH=$(htpasswd -bnBC 12 "" "$PW" | tr -d ':\n' | sed 's/$2y/$2a/') && \
              kubectl patch secret argocd-secret -n argocd --type=merge -p "{\"stringData\":{\"admin.password\":\"$HASH\",\"admin.passwordMtime\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}}";
          volumeMounts:
            - name: plaintext
              mountPath: /secrets
      volumes:
        - name: plaintext
          secret:
            secretName: argocd-admin-plaintext
```

## Validation
```bash
kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin.password}' | base64 -d
kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin.passwordMtime}' | base64 -d
```
Check you can log into `https://argocd.oremuslabs.app` and that `argocd-server` is exposed via the Traefik IngressRoute defined in `apps/platform/argocd-config/base/ingressroute.yaml`.

## Security considerations
- Never commit the plaintext password.
- Keep the bcrypt hash and `admin.passwordMtime` tightly coupled so Argo CD detects rotations reliably.
- Align the cost factor with your policy before rotating; regenerate both the hash and the timestamp simultaneously.

## Next steps
1. Keep `docs/onepassword-connect.md` and the OnePassword resources (`op://.../cloudflare-api-token/credential`) up to date so your certificates and ClusterIssuer stay healthy.
2. Confirm your load-balancer DNS (`argocd.oremuslabs.app`) continues to point at the cluster IP, especially after MetalLB/Traefik changes.
