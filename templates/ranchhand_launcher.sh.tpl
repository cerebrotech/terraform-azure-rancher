#!/usr/bin/env bash
set -e

bin="ranchhand"
workdir="rancher-provision"
artifact="ranchhand_${version}_${distro}_amd64.tar.gz"
url="https://github.com/dominodatalab/ranchhand/releases/download/v${version}/$artifact"

if [[ ! -d $workdir ]]; then
  mkdir -p $workdir
fi
cd $workdir

if [[ ! -f $bin ]]; then
  if [[ ! -f $artifact ]]; then
    curl -sLO $url
  fi
  tar -xzf $artifact && rm $artifact
fi

./$bin run \
  --node-ips "${node_ips}" \
  --internal-ips "${internal_ips}" \
  --ssh-user "${ssh_user}" \
  --ssh-proxy-host "${ssh_proxy_host}" \
  --ssh-proxy-user "${ssh_proxy_user}" \
  --ssh-key-path ${ssh_key}
