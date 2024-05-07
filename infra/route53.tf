resource "aws_route53_record" "route53_record" {
  name    = "bean.tonycava.dev"
  type    = "CNAME"
  ttl     = "300"
  zone_id = var.route53_zone_id

  depends_on = [
    aws_elastic_beanstalk_environment.tonycava_application_environment,
  ]

  records = [aws_elastic_beanstalk_environment.tonycava_application_environment.endpoint_url]
}
