resource "cloudflare_record" "k8s" {
  domain = "mskrajnowski.cloud"
  name   = "k8s"
  value  = "${hcloud_server.k8s_master.ipv4_address}"
  type   = "A"
  ttl    = 60
}
