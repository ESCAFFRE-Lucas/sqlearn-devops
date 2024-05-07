resource "aws_s3_bucket" "tonycava_bucket" {
  bucket = "${var.application_name}-deployments"
}


resource "aws_s3_object" "docker_object" {
  bucket = aws_s3_bucket.tonycava_bucket.id

  key    = local.s3-file_path
  source = data.archive_file.source.output_path
}
