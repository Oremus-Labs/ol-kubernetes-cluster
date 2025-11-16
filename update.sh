#!/usr/bin/env bash
set -euo pipefail

HOSTS=(10.10.10.3 10.10.10.4 10.10.10.5 10.10.10.6 10.10.10.7 10.10.10.8)
USER=olfa

CLEAN_SCRIPT=$(cat <<'EOS'
#!/bin/sh
set -eu
ROOT="/var/snap/microk8s/common/var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io"
NSENTER="nsenter --mount=/proc/1/ns/mnt --"
[ -d "$ROOT" ] || exit 0
find "$ROOT" -maxdepth 2 -type d -name globalmount 2>/dev/null | while read gm; do
  $NSENTER umount "$gm" 2>/dev/null || \
  $NSENTER umount -l "$gm" 2>/dev/null || \
  $NSENTER umount -f -l "$gm" 2>/dev/null || true
  rm -rf "$gm" 2>/dev/null || true
  mkdir -p "$gm"
  chmod 0755 "$gm"
done

EOS
)

UNIT_FILE=$(cat <<'EOS'
[Unit]
Description=Clean Longhorn CSI globalmounts before kubelet
DefaultDependencies=no
Before=containerd.service snap.microk8s.daemon-kubelet.service
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/longhorn-globalmount-clean.sh

[Install]
WantedBy=multi-user.target
EOS
)

for host in "${HOSTS[@]}"; do
  echo "Configuring $host..."
  ssh -o StrictHostKeyChecking=no "$USER@$host" "sudo tee /usr/local/sbin/longhorn-globalmount-clean.sh >/dev/null" <<< "$CLEAN_SCRIPT"
  ssh "$USER@$host" "sudo chmod +x /usr/local/sbin/longhorn-globalmount-clean.sh"
  ssh "$USER@$host" "sudo tee /etc/systemd/system/longhorn-globalmount-clean.service >/dev/null" <<< "$UNIT_FILE"
  ssh "$USER@$host" "sudo systemctl daemon-reload && sudo systemctl enable --now longhorn-globalmount-clean.service"
done

echo "Done. A reboot will run the cleaner before kubelet; you can also start it now via systemctl."
