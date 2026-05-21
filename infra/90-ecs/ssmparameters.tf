resource "aws_ssm_parameter" "dns_namespace" {
  name  = "${var.project_name}-${var.environment}-dns-namespace"
  type  = "String"
  value = aws_service_discovery_private_dns_namespace.main.id
  overwrite = true
}

resource "aws_ssm_parameter" "cloudmap_dns" {

  for_each = toset(local.cloudmap_services)

  name = "/${var.project_name}/${var.environment}/${each.key}-dns"

  type = "String"

  value = "${each.key}.${aws_service_discovery_private_dns_namespace.main.name}"

  overwrite = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-${each.key}-dns"
    }
  )
}