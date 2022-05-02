# terraform modules must declare which providers, they require


terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      # minimum provider version
      version = ">= 1.33.2"
    }
  }
  # version of terraform cli
  required_version = ">= 1.1"
}
