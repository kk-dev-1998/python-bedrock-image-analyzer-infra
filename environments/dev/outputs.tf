output "ecr_repository_url" {
  description = "Destination for docker push. Appending :<tag> to this becomes the image_uri"
  value       = module.ecr.repository_url
}

output "api_endpoint" {
  description = "API Gateway endpoint"
  value       = try(module.apigateway.api_endpoint, null)
}