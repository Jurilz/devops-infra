
variable "location" {
  default           = "nbg1"
}

variable "master_label" {
    default         = "master_cluster"
}

variable "hcloud_token" {
    type            = string
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
    token           = var.hcloud_token
}

# for connection with nodes via ssh a key must be added
resource "hcloud_ssh_key" "default" {
    name            = "hcloud_key"
    public_key      = file("${path.module}/tf-hetzner.pub")
  
}


# Create ${count} server
resource "hcloud_server" "master" {
    count           = "2"
    name            = "jupiter-${count.index}"
    image           = "ubuntu-20.04"
    
    # CPUs: 2  RAM: 4 GB  SSD: 40 GB   Traffic: 20 TB  cost: 5.83 €/mo
    server_type     = "cx21"

    # Nuernberg
    location        = var.location

    # SSH key IDs or names which should be injected into the server
    ssh_keys        = [hcloud_ssh_key.default.id]

    labels = {
        type        = var.master_label
    }

    network {
        network_id  = hcloud_network.devops_network.id
    }

    # **Note**: the depends_on is important when directly attaching the
    # server to a network. Otherwise Terraform will attempt to create
    # server and sub-network in parallel. This may result in the server
    # creation failing randomly.
    depends_on = [
        hcloud_network_subnet.devops-subnet
    ]
}


# network setup
resource "hcloud_network" "devops_network" {
    name            = "devops-network"
    ip_range        = "10.0.0.0/16" 
}

# provides a hetzner cloud network subnet
resource "hcloud_network_subnet" "devops-subnet" {
    network_id      = hcloud_network.devops_network.id
    type            = "cloud"
    network_zone    = "eu-central"
    ip_range        = "10.0.1.0/24"
}

# provides a hetzner cloud load balancer
resource "hcloud_load_balancer" "devops-load-balancer" {
    name                = "devops-load-balancer"
    # services: 5   targets: 25     certificates: 10    cost: 5.83 €/mo
    load_balancer_type  = "lb11"
    location            =  var.location
    algorithm {
      type              = "round_robin"
    }
}

resource "hcloud_load_balancer_network" "load-balancer-network" {
  load_balancer_id      = hcloud_load_balancer.devops-load-balancer.id
  subnet_id             = hcloud_network_subnet.devops-subnet.id
}

resource "hcloud_load_balancer_target" "load_balancer_target" {
  type              = "label_selector"
  load_balancer_id  = hcloud_load_balancer.devops-load-balancer.id
  label_selector    = "type=${var.master_label}"
}


resource "hcloud_load_balancer_service" "http_service" {
  load_balancer_id = hcloud_load_balancer.devops-load-balancer.id
  protocol         = "tcp"
  listen_port      = "80"
  destination_port = "80"
}

resource "hcloud_load_balancer_service" "https_service" {
  load_balancer_id = hcloud_load_balancer.devops-load-balancer.id
  protocol         = "tcp"
  listen_port      = "443"
  destination_port = "443"
}