# Compute Module - EC2 Instances, Key Pairs, IAM Profiles
# Manages EC2 instances with security best practices

# AMI Data Source - Configurable filters for Ubuntu/Amazon Linux/custom AMIs
data "aws_ami" "this" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = var.ami_owners

  dynamic "filter" {
    for_each = var.ami_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# SSH Key Pair - Conditional creation with file or string input
resource "aws_key_pair" "main" {
  count = var.create_key_pair ? 1 : 0

  key_name   = "${var.project_name}-${var.environment}-keypair"
  public_key = var.ssh_public_key != null ? var.ssh_public_key : file(var.ssh_public_key_path)

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-keypair"
    }
  )
}

# IAM Instance Profile - Optional, for attaching IAM roles
resource "aws_iam_instance_profile" "main" {
  count = var.create_instance_profile ? 1 : 0

  name = "${var.project_name}-${var.environment}-instance-profile"
  role = var.iam_role_name

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-instance-profile"
    }
  )
}

# EC2 Instance - Fully configurable with security best practices
resource "aws_instance" "main" {
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.this[0].id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip_address

  key_name = var.create_key_pair ? aws_key_pair.main[0].key_name : var.existing_key_pair_name

  iam_instance_profile = var.create_instance_profile ? aws_iam_instance_profile.main[0].name : var.existing_instance_profile_name

  # IMDSv2 enforcement (metadata security)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.require_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Root volume configuration with encryption
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = var.root_volume_encrypted
    delete_on_termination = var.root_volume_delete_on_termination
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-${var.environment}-root-volume"
      }
    )
  }

  # Additional EBS volumes support
  dynamic "ebs_block_device" {
    for_each = var.additional_ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      encrypted             = ebs_block_device.value.encrypted
      delete_on_termination = ebs_block_device.value.delete_on_termination
      tags = merge(
        var.tags,
        {
          Name = "${var.project_name}-${var.environment}-${ebs_block_device.value.device_name}"
        }
      )
    }
  }

  # User data with replace-on-change option
  user_data                   = var.user_data
  user_data_replace_on_change = var.user_data_replace_on_change

  # CloudWatch detailed monitoring
  monitoring = var.enable_detailed_monitoring

  # Lifecycle configuration
  # Note: ignore_changes doesn't support conditional expressions
  # To enable AMI changes, manually edit this or use a separate module instance

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-instance"
    }
  )
}
