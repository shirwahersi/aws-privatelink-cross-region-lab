output "vpc_endpoint_service_name" {
  description = "The name of the VPC endpoint service"
  value       = aws_vpc_endpoint_service.endpoint_service.service_name
}
