#EC2 Auto Scaling Group
resource "aws_autoscaling_group" "websrv" {
  name                    = format("%s%s%s%s", var.customer_code, "asg", var.environment_code, "websrv01")
  default_cooldown        = 60
  target_group_arns       = [aws_lb_target_group.websrv.arn]
  vpc_zone_identifier     = [aws_subnet.priv_subnet_01.id,aws_subnet.priv_subnet_02.id]
  desired_capacity        = 2
  max_size                = 4
  min_size                = 2

  launch_template {
    id      = aws_launch_template.websrv.id
    version = "$Latest"
  }
}