#!/usr/bin/env bash
set -e

bin="./ranchhand"
workdir="rancher-provision"
artifact="ranchhand_${version}_${distro}_amd64.tar.gz"
url="https://github.com/dominodatalab/ranchhand/releases/download/v${version}/$artifact"
ssh_proxy_host="${ssh_proxy_host}"
ssh_proxy_user="${ssh_proxy_user}"
ssh_key_path=${ssh_key} # leave unquoted to ensure ~ expansion

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

if [[ -n "$ssh_proxy_host" ]]; then
  ssh_args="-o LogLevel=ERROR -o StrictHostKeyChecking=no -i $ssh_key_path"
  ssh_host_str="$ssh_proxy_user@$ssh_proxy_host"
  remote_key_path="$workdir/ssh_key"

  ssh $ssh_args $ssh_host_str mkdir -p $workdir
  scp $ssh_args $ssh_key_path $ssh_host_str:$remote_key_path
  rsync -ai --rsh="ssh $ssh_args" ./ $ssh_host_str:$workdir

  bin="ssh $ssh_args $ssh_host_str cd $workdir && $bin"
  ssh_key_path='$(pwd)/ssh_key'
fi

$bin run \
  --node-ips "${node_ips}" \
  --internal-ips "${internal_ips}" \
  --ssh-user "${ssh_user}" \
  --ssh-key-path $ssh_key_path

if [[ -n "$ssh_proxy_host" ]]; then
  ssh $ssh_args $ssh_host_str rm $remote_key_path
  rsync -ai --rsh="ssh $ssh_args" $ssh_host_str:$workdir/ ./
fi
