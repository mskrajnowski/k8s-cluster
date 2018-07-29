resource "hcloud_ssh_key" "mskrajnowski" {
  name       = "mskrajnowski"
  public_key = "${file("./keys/mskrajnowski.pub")}"
}
