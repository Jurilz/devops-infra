output "load_balancer_ipv4" {
  description = "Load balancer IP address"
  value = hcloud_load_balancer.devops-load-balancer.ipv4
}


output "servers_status" {
  value = {
    for server in hcloud_server.master :
    server.name => server.status
  }
}

output "servers_ips" {
  value = {
    for server in hcloud_server.master :
    server.name => server.ipv4_address
  }
}