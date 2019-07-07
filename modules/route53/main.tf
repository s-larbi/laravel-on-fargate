data "aws_route53_zone" "zone" {
  name = var.domain_name
}

# resource "aws_route53_zone" "zone" {
#   name = join(".", [var.stack_name, var.root_domain_name])
# }

# resource "aws_route53_record" "ns" {
#   zone_id = data.aws_route53_zone.zone.zone_id
#   name    = aws_route53_zone.zone.name
#   type    = "NS"
#   ttl     = "172800"

#   records = aws_route53_zone.zone.name_servers
# }

resource "aws_route53_record" "alias" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_hostname
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
