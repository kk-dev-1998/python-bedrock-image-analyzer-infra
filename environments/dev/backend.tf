terraform {
  backend "s3" {
    bucket       = "image-analysis-api-tfstate-f28ff5c3"
    key          = "image-analysis-api/dev/terraform.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
    encrypt      = true
  }
}