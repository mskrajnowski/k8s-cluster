variable "hcloud_token" {}
variable "hcloud_k8s_image" {}

provider "hcloud" {
  token = "${var.hcloud_token}"
}
