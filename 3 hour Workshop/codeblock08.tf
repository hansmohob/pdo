# Set VPC DHCP options for domain members
resource "aws_vpc_dhcp_options" "mmad01" {
  domain_name         = ##CORRUPT##
  domain_name_servers = ##CORRUPT##

  tags = {
    Name         = format("%s%s%s%s%s", var.customer_code, "dhc", var.environment_code, "mmad", "01"),
    resourcetype = "network"
    codeblock    = "codeblock08"
  }
}

resource "aws_vpc_dhcp_options_association" "mmad01" {
  vpc_id          = aws_vpc.vpc_01.id
  dhcp_options_id = aws_vpc_dhcp_options.mmad01.id
}

# Windows Domain join SSM setup
resource "aws_ssm_document" "domainjoin" {
  name          = format("%s%s%s%s", var.customer_code, "ssm", var.environment_code, "domainjoin")
  document_type = "Command"
  content = jsonencode(
    {
      "schemaVersion" = "2.2"
      "description"   = "Join instances to domain based on tag"
      "mainSteps" = [
        {
          "action" = "aws:domainJoin",
          "name"   = "domainJoin",
          "inputs" = {
            "directoryId"    = ##CORRUPT##
            "directoryName"  = ##CORRUPT##
            "dnsIpAddresses" = ##CORRUPT##
          }
        }
      ]
    }
  )

  tags = {
    Name         = format("%s%s%s%s", var.customer_code, "ssm", var.environment_code, "domainjoin")
    resourcetype = "identity"
    codeblock    = "codeblock08"
  }
}

resource "aws_ssm_association" "domainjoin" {
  name = aws_ssm_document.domainjoin.name
  targets {
    key    = "tag:domainjoin"
    values = ["mmad"]
  }
}
# IAM policy configuration
resource "aws_iam_role_policy_attachment" "ssm-mmad" {
  role       = aws_iam_role.websrv.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}
