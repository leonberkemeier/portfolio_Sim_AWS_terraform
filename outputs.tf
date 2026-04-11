# Outputs display useful information in your terminal after 'terraform apply' completes

output "rds_endpoint" {
  description = "Connection string for the PostgreSQL Database"
  value       = aws_db_instance.postgres.endpoint
}

output "database_name" {
  description = "The name of the database created"
  value       = aws_db_instance.postgres.db_name
}

output "layer2_gpu_private_ip" {
  description = "Private IP address of the EC2 GPU instance running the Analysis Engine"
  value       = aws_instance.analysis_engine.private_ip
}

output "frontend_cloudfront_url" {
  description = "URL of the CloudFront distribution hosting the Layer 3 React frontend"
  value       = aws_cloudfront_distribution.frontend_cdn.domain_name
}
