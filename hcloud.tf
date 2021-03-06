variable "hcloud_token" {}

provider "hcloud" {
  token = "${var.hcloud_token}"
}

resource "hcloud_ssh_key" "mskrajnowski" {
  name       = "mskrajnowski"
  public_key = "${file("./keys/mskrajnowski.pub")}"
}

resource "hcloud_server" "k8s_master" {
  name        = "k8s-master"
  server_type = "cx11"
  image       = "debian-9"
  location    = "nbg1"

  ssh_keys = [
    "${hcloud_ssh_key.mskrajnowski.name}",
  ]

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common",
      "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -",
      "add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/debian stretch stable'",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
      "add-apt-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'",
      "apt-get update",
      "apt-get install -y docker-ce kubelet kubeadm kubectl",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sysctl net.bridge.bridge-nf-call-iptables=1",
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

resource "hcloud_server" "k8s_worker" {
  count       = "1"
  name        = "k8s-worker-${count.index + 1}"
  server_type = "cx11"
  image       = "debian-9"
  location    = "nbg1"

  ssh_keys = [
    "${hcloud_ssh_key.mskrajnowski.name}",
  ]

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common",
      "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -",
      "add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/debian stretch stable'",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
      "add-apt-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'",
      "apt-get update",
      "apt-get install -y docker-ce kubelet kubeadm kubectl",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sysctl net.bridge.bridge-nf-call-iptables=1",
      "kubeadm join --token ${data.external.k8s_join.result.token} --discovery-token-ca-cert-hash sha256:${data.external.k8s_join.result.hash} ${hcloud_server.k8s_master.ipv4_address}:6443",
    ]
  }
}

output k8s_worker_ips {
  value = "${hcloud_server.k8s_worker.*.ipv4_address}"
}
