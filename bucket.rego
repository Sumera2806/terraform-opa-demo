package terraform.demo

default allow = false

allow if {
  input.resource_changes[_].change.after.content == "Hello, OPA!"
}
