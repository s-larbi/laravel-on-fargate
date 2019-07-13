provider "aws" {
  region  = var.aws_region
  version = "~> 2.8"
}

provider "aws" {
  region  = "us-east-1"
  alias   = "us-east-1"
  version = "~> 2.8"
}

terraform {
  backend "s3" {
    key                  = "main.tfstate"
    region               = "eu-west-2"
    workspace_key_prefix = "workspaces"
    dynamodb_table       = "terraform_locks"
  }
}