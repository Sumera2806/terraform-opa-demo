provider "local" {}

resource "local_file" "example" {
  content  = "Hello, OPA!"
  filename = "${path.module}/hello.txt"
}
