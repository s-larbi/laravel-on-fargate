output "ecs_alb_hostname" {
  value = aws_alb.main.dns_name
}

output "ecs_alb_zone_id" {
  value = aws_alb.main.zone_id
}