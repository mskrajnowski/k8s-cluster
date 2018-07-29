resource "hcloud_server" "k8s_snapshot" {
  # only used to create the debian-9-k8s base image on hcloud
  count       = "0"
  name        = "k8s-base"
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
      "apt-get install -y docker-ce kubelet kubeadm kubectl jq",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo net.ipv4.ip_forward=1 >>/etc/sysctl.conf",
      "echo net.bridge.bridge-nf-call-iptables=1 >>/etc/sysctl.conf",
    ]
  }
}
