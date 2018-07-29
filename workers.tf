resource "hcloud_server" "k8s_worker" {
  count       = "1"
  name        = "k8s-worker-${count.index + 1}"
  server_type = "cx11"
  image       = "${var.hcloud_k8s_image}"
  location    = "nbg1"

  ssh_keys = [
    "${hcloud_ssh_key.mskrajnowski.name}",
  ]

  provisioner "remote-exec" {
    inline = [
      "sysctl -p",
      "kubeadm join --token ${data.external.k8s_join.result.token} --discovery-token-ca-cert-hash sha256:${data.external.k8s_join.result.hash} ${hcloud_server.k8s_master.ipv4_address}:6443",
    ]
  }
}

output k8s_worker_ips {
  value = "${hcloud_server.k8s_worker.*.ipv4_address}"
}
