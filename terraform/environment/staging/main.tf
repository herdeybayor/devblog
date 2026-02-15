module "networking" {
  source = "../../modules/networking"
  project_name = var.project_name
  environment = var.environment
  map_public_ip_on_launch = false
}

# Fetch the latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "main" {
  key_name = "${var.project_name}-${var.environment}-key"
  public_key = file("~/.ssh/devblog.pub")
  
  tags = {
    Name = "${var.project_name}-${var.environment}-key"
  }
}

resource "aws_instance" "main" {
  ami = data.aws_ami.ubuntu.image_id
  instance_type = var.instance_type
  subnet_id = module.networking.public_subnet_id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name = aws_key_pair.main.key_name
  # associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-${var.environment}-instance"
  }
}