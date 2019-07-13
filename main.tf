data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
  stack_name = terraform.workspace == "default" ? var.project_name : join("-", [var.project_name, terraform.workspace])
  hostname   = terraform.workspace == "default" ? var.domain : join(".", [terraform.workspace, var.domain])
}

// TODO any other subdomain should redirect to APEX

module "iam" {
  source = "./modules/iam"
}

// TODO use VPC endpoints for ECR and ECS (and eventually SQS and S3) rather than NAT Gateway
// https://noise.getoto.net/2019/01/25/setting-up-aws-privatelink-for-aws-fargate-amazon-ecs-and-amazon-ecr/
module "vpc" {
  source        = "./modules/vpc"
  stack_name    = local.stack_name
  b_nat_gateway = true
}

module "route53" {
  source       = "./modules/route53"
  domain       = var.domain
  hostname     = local.hostname
  alb_hostname = module.ecs.ecs_alb_hostname
  alb_zone_id  = module.ecs.ecs_alb_zone_id
  
  providers = {
    aws = "aws.us-east-1"
  }
}

module "aurora" {
  source     = "./modules/aurora"
  stack_name = local.stack_name
  subnet_ids = module.vpc.private_subnet_ids
  vpc_id     = module.vpc.id
}

module "acm" {
  source         = "./modules/acm"
  hostname       = local.hostname
  hosted_zone_id = module.route53.hosted_zone_id
}

module "ecs" {
  source                     = "./modules/ecs"
  stack_name                 = local.stack_name
  vpc_id                     = module.vpc.id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  role                       = module.iam.ecs_role
  certificate_arn            = module.acm.certificate_arn
  hostname                   = local.hostname
  aurora_endpoint            = module.aurora.aurora_endpoint
  aurora_port                = module.aurora.aurora_port
  aurora_db_name             = module.aurora.aurora_db_name
  aurora_db_username         = module.aurora.aurora_db_username
  aurora_master_password     = module.aurora.aurora_master_password
  ecr_laravel_repository_uri = module.ecr.laravel_repository_uri
  ecr_nginx_repository_uri   = module.ecr.nginx_repository_uri
}

module "ecr" {
  source               = "./modules/ecr"
  stack_name           = replace(local.stack_name, "/[^a-zA-Z0-9]+/", "")
  ci_pipeline_user_arn = module.iam.ci_pipeline_arn
  ecs_role             = module.iam.ecs_role
}

// TODO remove NAT Gateway

// TODO Artisan workers & crons
