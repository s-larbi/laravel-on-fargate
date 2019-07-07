output "aurora_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}

output "aurora_reader_endpoint" {
  value = aws_rds_cluster.aurora_cluster.reader_endpoint
}

output "aurora_cluster_id" {
  value = aws_rds_cluster.aurora_cluster.id
}

output "aurora_master_password" {
  value = random_string.rds_master_password.result
}

output "aurora_db_name" {
  value = aws_rds_cluster.aurora_cluster.database_name
}

output "aurora_db_username" {
  value = aws_rds_cluster.aurora_cluster.master_username
}

output "aurora_port" {
  value = aws_rds_cluster.aurora_cluster.port
}
