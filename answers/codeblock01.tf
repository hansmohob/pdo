# Create a Resource Group for Terraform created instances

resource "aws_resourcegroups_group" "pdo" {
  name        = format("%s%s%s%s", var.customer_code, "rgg", var.environment_code, "pdo")
  description = "Planetry Defence Organization environment resources"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": [
    {
      "Key": "customer",
      "Values": ["${var.customer}"]
    }
  ]
}
JSON
  }

  tags = {
    Name         = format("%s%s%s%s", var.customer_code, "rgg", var.environment_code, "pdo")
    resourcetype = "scaffold"
    codeblock    = "codeblock01"
  }
}