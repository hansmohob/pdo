#Load Balancer S3 bucket policy https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html
data "aws_iam_policy_document" "websrv" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::652711504416:root",
                     "arn:aws:iam::156460612806:root",
                     "arn:aws:iam::127311923021:root",
                     "arn:aws:iam::033677994240:root",
                     "arn:aws:iam::027434742980:root",
                     "arn:aws:iam::797873946194:root"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.websrv.arn,
      "${aws_s3_bucket.websrv.arn}/albaccesslogs/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "websrv" {
  bucket = aws_s3_bucket.websrv.id
  policy = data.aws_iam_policy_document.websrv.json
}