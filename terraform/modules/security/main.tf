# Security Module - Security Groups with Rule Templating
# Manages security groups with predefined and dynamic rules

# Security Group
resource "aws_security_group" "main" {
  name        = var.security_group_name != null ? var.security_group_name : "${var.project_name}-${var.environment}-sg"
  description = var.security_group_description != null ? var.security_group_description : "Security group for ${var.project_name} ${var.environment}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = var.security_group_name != null ? var.security_group_name : "${var.project_name}-${var.environment}-sg"
      Environment = var.environment
    }
  )
}

# Predefined SSH Rule
resource "aws_security_group_rule" "ssh" {
  count = var.enable_ssh_rule ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  security_group_id = aws_security_group.main.id
  description       = "SSH access"
}

# Predefined HTTP Rule
resource "aws_security_group_rule" "http" {
  count = var.enable_http_rule ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.http_cidr_blocks
  security_group_id = aws_security_group.main.id
  description       = "HTTP access"
}

# Predefined HTTPS Rule
resource "aws_security_group_rule" "https" {
  count = var.enable_https_rule ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.https_cidr_blocks
  security_group_id = aws_security_group.main.id
  description       = "HTTPS access"
}

# Dynamic Custom Ingress Rules
resource "aws_security_group_rule" "custom_ingress" {
  for_each = { for idx, rule in var.ingress_rules : idx => rule }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  security_group_id = aws_security_group.main.id
  description       = lookup(each.value, "description", "Custom ingress rule")
}

# Dynamic Custom Egress Rules
resource "aws_security_group_rule" "custom_egress" {
  for_each = { for idx, rule in var.egress_rules : idx => rule }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  security_group_id = aws_security_group.main.id
  description       = lookup(each.value, "description", "Custom egress rule")
}

# Default Egress Rule (allow all outbound) - only if no custom egress rules
resource "aws_security_group_rule" "default_egress" {
  count = length(var.egress_rules) == 0 && var.enable_default_egress ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
  description       = "Allow all outbound traffic"
}
