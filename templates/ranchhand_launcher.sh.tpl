#!/usr/bin/env bash
set -e

artifact="ranchhand_${version}_${distro}_amd64.tar.gz"
url="https://github.com/dominodatalab/ranchhand/releases/download/v${version}/$artifact"

if [[ ! -f ./ranchhand ]]; then
  if [[ ! -f $artifact ]]; then
    curl -sLO $url
  fi
  tar -xzf $artifact
fi

./ranchhand \
  --node-ips "${node_ips}" \
  --ssh-user "${ssh_user}" \
  --ssh-key-path ${ssh_key}
