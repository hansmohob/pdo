# LaunchTemplate
resource "aws_launch_template" "websrv" {
  name                   = format("%s%s%s%s", var.customer_code, "ltp", var.environment_code, "websrv01")
  description            = "Launch Template for Windows IIS Web server Auto Scaling Group"
  image_id               = var.ami_id01
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.ec2_keypair_01.key_name
  vpc_security_group_ids = [aws_security_group.app01.id]
  ebs_optimized          = true

  user_data = base64encode(templatefile("webserver_user_data.ps1",
    {
      S3Bucket = "s3://${aws_s3_bucket.websrv.bucket}/webserverfiles/"
    }
    )
  )

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      delete_on_termination = true
      volume_size           = 50
      volume_type           = "gp3"
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.websrv.id
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name         = format("%s%s%s%s", var.customer_code, "ec2", var.environment_code, "websrvasg")
      domainjoin   = "mmad"
      resourcetype = "compute"
      codeblock    = "task06"
    }
  }
}