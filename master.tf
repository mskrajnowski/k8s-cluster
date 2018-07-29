resource "hcloud_server" "k8s_master" {
  name        = "k8s-master"
  server_type = "cx11"
  image       = "${var.hcloud_k8s_image}"
  location    = "nbg1"

  ssh_keys = [
    "${hcloud_ssh_key.mskrajnowski.name}",
  ]

  provisioner "remote-exec" {
    inline = [
      "sysctl -p",
      "kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${self.ipv4_address} --apiserver-cert-extra-sans=${self.ipv4_address}",
    ]
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no root@${hcloud_server.k8s_master.ipv4_address}:/etc/kubernetes/admin.conf ./kubectl.conf"
  }
}

output "k8s_master_ip" {
  value = "${hcloud_server.k8s_master.ipv4_address}"
}

data "external" "k8s_join" {
  program = [
    "./programs/k8s_master_ssh",
    "root@${hcloud_server.k8s_master.ipv4_address}",
    "./programs/k8s_join_data",
  ]
}
