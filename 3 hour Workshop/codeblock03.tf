# Create S3 bucket for web server files and upload local files

##CORRUPT##
  bucket_prefix = format("%s%s%s%s", var.customer_code, "sss", var.environment_code, "websrv")
  force_destroy = true

  tags = {
    name         = format("%s%s%s%s", var.customer_code, "sss", var.environment_code, "websrv"),
    resourcetype = "storage"
    codeblock    = "codeblock03"
  }
}

resource "aws_s3_bucket_public_access_block" "websrv" {
  bucket                  = aws_s3_bucket.websrv.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "websrv" {
  for_each = fileset("./existing_webserverfiles/", "**")
  bucket   = aws_s3_bucket.websrv.id
  key      = "webserverfiles/${each.value}"
  source   = "./existing_webserverfiles/${each.value}"
  etag     = filemd5("./existing_webserverfiles/${each.value}")
}
