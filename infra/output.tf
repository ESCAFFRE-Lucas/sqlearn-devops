output "app_version" {
  value = aws_elastic_beanstalk_application.tonycava_application.name
}

output "app_url" {
  value = aws_elastic_beanstalk_environment.tonycava_application_environment.name
}

output "db_endpoint" {
  value = aws_db_instance.default.endpoint
}