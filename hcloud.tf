variable "hcloud_token" {}

provider "hcloud" {
  token = "${var.hcloud_token}"
}

resource "hcloud_ssh_key" "mskrajnowski_key" {
  name       = "mskrajnowski"
  public_key = "${file("./keys/mskrajnowski.pub")}"
}

resource "hcloud_server" "k8s_master" {
  name        = "k8s-master"
  server_type = "cx11"
  image       = "debian-9"
  location    = "nbg1"

  ssh_keys = ["mskrajnowski"]
}

output "k8s_master_ip" {
  value = "${hcloud_server.k8s_master.ipv4_address}"
}

output "k8s_master_ssh" {
  value = "ssh root@${hcloud_server.k8s_master.ipv4_address}"
}
