# Create a private key for use with EC2 instances

resource "tls_private_key" "ec2_keypair_01" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_keypair_01" {
  key_name   = format("%s%s%s%s", var.customer_code, "akp", var.environment_code, "ec201")
  public_key = tls_private_key.ec2_keypair_01.public_key_openssh
}

resource "aws_secretsmanager_secret" "ec2_keypair_01" {
  name                    = format("%s%s%s%s", var.customer_code, "sms", var.environment_code, "ec201")
  description             = " EC2 private key"
  recovery_window_in_days = 0

  tags = {
    Name      = format("%s%s%s%s", var.customer_code, "sms", var.environment_code, "ec201")
    rtype     = "security"
    codeblock = "landingzone-base"
  }
}

resource "aws_secretsmanager_secret_version" "ec2_keypair_01" {
  secret_id     = aws_secretsmanager_secret.ec2_keypair_01.id
  secret_string = tls_private_key.ec2_keypair_01.private_key_pem
}

# Create a Resource Group for Terraform created instances

resource "aws_resourcegroups_group" "Terraform" {
  name        = format("%s%s%s%s", var.customer_code, "rgg", var.environment_code, "demoall")
  description = "terrafrom created demo environment resources"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": [
    {
      "Key": "Provisioner",
      "Values": ["Terraform"]
    },
    {
      "Key": "Customer",
      "Values": ["${var.customer_name}"]
    },
    {
      "Key": "Environment",
      "Values": ["${var.env_name}"]
    }
  ]
}
JSON
  }

  tags = {
    Name      = format("%s%s%s%s", var.customer_code, "rgg", var.environment_code, "demoall")
    rtype     = "scaffold"
    codeblock = "landingzone-base"
  }
}

# IAM Policy Configuration
 
resource "aws_iam_role" "ec2admin" {
  name               = format("%s%s%s%s", var.customer_code, "iar", var.environment_code, "ec2admin")
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "ec2.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = format("%s%s%s%s", var.customer_code, "iar", var.environment_code, "ssm")
    rtype     = "identity"
    codeblock = "landingzone-base"
  }
}

resource "aws_iam_role_policy" "ec2describe" {
  name   = format("%s%s%s%s", var.customer_code, "irp", var.environment_code, "ec2describe")
  role   = aws_iam_role.ec2admin.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2describe-ec2admin" {
  role       = aws_iam_role.ec2admin.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "secretdescribe" {
  name   = format("%s%s%s%s", var.customer_code, "irp", var.environment_code, "ec2secrets")
  role   = aws_iam_role.ec2admin.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets-ec2admin" {
  role       = aws_iam_role.ec2admin.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2admin" {
  name = format("%s%s%s%s", var.customer_code, "iap", var.environment_code, "ec2admin")
  role = aws_iam_role.ec2admin.name

  tags = {
    Name      = format("%s%s%s%s", var.customer_code, "iap", var.environment_code, "ec2admin")
    rtype     = "identity"
    codeblock = "landingzone-base"
  }
}