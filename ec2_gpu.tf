# Fetch the latest Deep Learning AMI optimized for PyTorch/NVIDIA
data "aws_ami" "deep_learning" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning AMI GPU PyTorch * (Ubuntu 22.04) *"]
  }
}

# ----------------------------------------------------------------------
# NEW: IAM Role so the EC2 GPU Instance can read from SQS
# ----------------------------------------------------------------------
resource "aws_iam_role" "layer2_role" {
  name = "${var.project_name}-layer2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "layer2_sqs_policy" {
  role       = aws_iam_role.layer2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_instance_profile" "layer2_profile" {
  name = "${var.project_name}-layer2-profile"
  role = aws_iam_role.layer2_role.name
}

# Security group for the EC2 Instance (Layer 2)
resource "aws_security_group" "layer2_sg" {
  name        = "${var.project_name}-layer2-sg"
  description = "Security group for Analysis Engine"
  vpc_id      = aws_vpc.main.id

  # Allow inbound HTTP requests (e.g., if you run an API here) from the VPC
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The EC2 Instance
resource "aws_instance" "analysis_engine" {
  ami           = data.aws_ami.deep_learning.id
  instance_type = "g4dn.xlarge"   # NVIDIA T4 GPU instance, great for Ollama/LLaMa2
  subnet_id     = aws_subnet.private.id
  
  vpc_security_group_ids = [aws_security_group.layer2_sg.id]

  # Attach the IAM role to give permissions (e.g. SQS polling)
  iam_instance_profile = aws_iam_instance_profile.layer2_profile.name

  # User data acts as a startup script. We can use it to initialize basic dependencies.
  user_data = <<-EOF
              #!/bin/bash
              echo "Starting up Analysis Engine Node..."
              # You could install missing dependencies or pull your git repo here
              # curl -fsSL https://ollama.com/install.sh | sh
              EOF

  tags = {
    Name = "${var.project_name}-layer2-analysis"
  }
}
