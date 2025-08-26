package terraform.demo

default allow = false

# Active create/update (ignore no-ops/destroys)
is_active_change(rc) {
  some a
  a := rc.change.actions[_]
  a == "create" or a == "update"
}

# Convenience getter
after(rc) := rc.change.after

# Sets of bucket names by resource type in this plan
buckets := { after(rc).bucket |
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket"
  is_active_change(rc)
}

sse_buckets := { after(rc).bucket |
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket_server_side_encryption_configuration"
  is_active_change(rc)
}

pab_buckets := { after(rc).bucket |
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket_public_access_block"
  is_active_change(rc)
}

# ---- Deny rules ----

# 1) Require server-side encryption configuration per bucket
deny[msg] {
  b := buckets[_]
  not b in sse_buckets
  msg := sprintf("S3 bucket %q is missing server-side encryption configuration resource.", [b])
}

# 2) Require Public Access Block resource per bucket
deny[msg] {
  b := buckets[_]
  not b in pab_buckets
  msg := sprintf("S3 bucket %q is missing a Public Access Block resource.", [b])
}

# 3) Forbid public ACLs (explicit)
deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket"
  is_active_change(rc)
  a := after(rc)
  a.acl == "public-read"  or
  a.acl == "public-read-write" or
  a.acl == "website"
  msg := sprintf("S3 bucket %q uses a public ACL (%v).", [a.bucket, a.acl])
}

# 4) Forbid grants to AllUsers / AuthenticatedUsers URIs
deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket"
  is_active_change(rc)
  g := after(rc).grant[_]
  g.type == "Group"
  (g.uri == "http://acs.amazonaws.com/groups/global/AllUsers" or
   g.uri == "http://acs.amazonaws.com/groups/global/AuthenticatedUsers")
  msg := sprintf("S3 bucket %q grants access to %v.", [after(rc).bucket, g.uri])
}

# 5) Enforce required tags (Owner, Environment)
deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket"
  is_active_change(rc)
  tags := object.get(after(rc), "tags", {})
  not has_key(tags, "Owner")
  msg := sprintf("S3 bucket %q missing required tag: Owner.", [after(rc).bucket])
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket"
  is_active_change(rc)
  tags := object.get(after(rc), "tags", {})
  not has_key(tags, "Environment")
  msg := sprintf("S3 bucket %q missing required tag: Environment.", [after(rc).bucket])
}

# Gate
allow {
  count(deny) == 0
}
