package terraform.demo

default allow = false

# Allow only if content is exactly "Hello, OPA!"
allow if {
  input.resource_changes[_].change.after.content == "Hello, OPA!"
}

