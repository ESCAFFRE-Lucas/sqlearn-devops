data "archive_file" "source" {
  type        = "zip"
  source_dir  = "./app"
  output_path = "./build/deployements-${uuid()}.zip"
}