# Phase 1: Secure AWS Infrastructure + Logging Setup using Terraform

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "secure-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "secure-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_instance" "web" {
  ami                    = "ami-079db87dc4c10ac91" # Amazon Linux 2 AMI for us-east-1 (latest as of Apr 2025)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = {
    Name = "web-instance"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "static" {
  bucket = "secure-static-content-${random_id.bucket.hex}"
  force_destroy = true
}

resource "random_id" "bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "s3-access-logs-${random_id.logs.hex}"
  force_destroy = true
}

resource "random_id" "logs" {
  byte_length = 4
}

resource "aws_s3_bucket_logging" "log_settings" {
  bucket = aws_s3_bucket.static.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "logs/"
}

resource "aws_flow_log" "vpc_logs" {
  log_destination      = aws_cloudwatch_log_group.vpc_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.flow_log_role.arn
}

resource "aws_cloudwatch_log_group" "vpc_logs" {
  name = "/vpc/flow-logs"
  retention_in_days = 7
}

resource "aws_iam_role" "flow_log_role" {
  name = "flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "flow_log_policy" {
  role       = aws_iam_role.flow_log_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = ["s3:GetBucketAcl"],
        Resource  = "${aws_s3_bucket.access_logs.arn}"
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = ["s3:PutObject"],
        Resource  = "${aws_s3_bucket.access_logs.arn}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "secure-trail"
  s3_bucket_name                = aws_s3_bucket.access_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_policy]
}
# ------------------ OUTPUTS ------------------
output "public_instance_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "static_s3_bucket_name" {
  description = "S3 Bucket for static content"
  value       = aws_s3_bucket.static.bucket
}

output "logs_s3_bucket_name" {
  description = "S3 Bucket for storing access logs"
  value       = aws_s3_bucket.access_logs.bucket
}

# ------------------ VARIABLES (optional in future use) ------------------
# You can refactor hardcoded values to variables like below:

# variable "vpc_cidr" {
#   default = "10.0.0.0/16"
# }

# variable "subnet_cidr" {
#   default = "10.0.1.0/24"
# }

# variable "instance_type" {
#   default = "t2.micro"
# }

# variable "ami_id" {
#   default = "ami-079db87dc4c10ac91"
# }
