# ==============================================================================
# Outputs Configuration
# ==============================================================================

# 1. Public IP of the EC2 Instance (Mandatory Requirement)
output "public_ip" {
  description = "The public IPv4 address of the Nginx EC2 instance"
  value       = aws_instance.nginx_server.public_ip
}

# 2. EC2 Instance ID
output "instance_id" {
  description = "The ID of the provisioned EC2 instance"
  value       = aws_instance.nginx_server.id
}

# 3. Direct HTTP Web URL
output "nginx_url" {
  description = "Direct HTTP URL to access the custom Nginx web page"
  value       = "http://${aws_instance.nginx_server.public_ip}"
}
