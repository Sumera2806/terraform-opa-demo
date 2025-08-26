provider "local" {}

resource "local_file" "example" {
  content  = "Bad value!"
  filename = "${path.module}/hello.txt"
}
