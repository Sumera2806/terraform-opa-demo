package terraform.s3

# Deny if a bucket does not have public access blocks
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"

  not input.resource_changes[_].change.after.block_public_acls
  msg := sprintf("Bucket %s must block public ACLs", [resource.name])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"

  not input.resource_changes[_].change.after.block_public_policy
  msg := sprintf("Bucket %s must block public policies", [resource.name])
}
