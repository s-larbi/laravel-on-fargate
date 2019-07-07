output "stack_name" {
  value = local.stack_name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "iam_ci_pipeline_access_key_id" {
  value = module.iam.ci_pipeline_access_key_id
}

output "iam_ci_pipeline_access_key_secret" {
  value = module.iam.ci_pipeline_access_key_secret
}

output "iam_ci_pipeline_arn" {
  value = module.iam.ci_pipeline_arn
}

output "route53_hosted_zone_id" {
  value = module.route53.hosted_zone_id
}

output "acm_certificate_arn" {
  value = module.acm.certificate_arn
}

output "vpc_id" {
  value = module.vpc.id
}

output "vpc_public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "vpc_public_subnet_id" {
  value = module.vpc.public_subnet_ids[0]
}

output "vpc_private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "vpc_public_subnet_cidr_blocks" {
  value = module.vpc.public_subnet_cidr_blocks
}

output "vpc_private_subnet_cidr_blocks" {
  value = module.vpc.private_subnet_cidr_blocks
}

output "ecs_alb_hostname" {
  value = module.ecs.ecs_alb_hostname
}

output "aurora_endpoint" {
  value = module.aurora.aurora_endpoint
}

output "aurora_reader_endpoint" {
  value = module.aurora.aurora_reader_endpoint
}

output "aurora_cluster_id" {
  value = module.aurora.aurora_cluster_id
}

output "aurora_master_password" {
  value = module.aurora.aurora_master_password
}

output "aurora_db_name" {
  value = module.aurora.aurora_db_name
}

output "aurora_db_username" {
  value = module.aurora.aurora_db_username
}

output "ecr_laravel_repository_uri" {
  value = module.ecr.laravel_repository_uri
}

output "ecr_nginx_repository_uri" {
  value = module.ecr.nginx_repository_uri
}