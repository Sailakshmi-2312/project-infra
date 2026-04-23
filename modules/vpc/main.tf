terraform {
    required_version = ">=1.6.0"
  required_providers {
    aws ={
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

locals {
  name= "${var.project_name}-${var.environment}"
  common_tags = merge(
    {
        Module = "vpc"
        Environemnt = var.environment
    },
    var.tags
  )
}

data "aws_region" current {}

# VPC 

resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
  tags = merge(local.common_tags,{
    Name = "${local.name}-vpc"
  })
}

#IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.common_tags,{
    Name = "${local.name}-igw"
  })
}

#PUBLIC SUBNET

resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags,{
    Name = "${local.name}-public-${var.azs[count.index]}"
    Tier = "public"
  })
}

#private_subnet

resource "aws_subnet" "private" {
  count = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(local.common_tags,{
    Name = "${local.name}-private-${var.azs[count.index]}"
    Tier = "private"
  })
}


# eip for nat

resource "aws_eip" "nat" {
    count = var.single_nat_gateway ? 1 : length(var.azs)
    domain = "vpc"
    tags = merge(local.common_tags,{
        name= "${local.name}-nat-eip-${count.index+1}"
    })
    depends_on = [ aws_internet_gateway.main ]
}
#NAT GATEWAY
resource "aws_nat_gateway" "main" {
  count = var.single_nat_gateway ? 1 : length(var.azs)

    allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.name}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

#route table 

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}



resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

#s3 gateway endpoint

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(local.common_tags, {
    Name = "${local.name}-s3-endpoint"
  })
}

#sg for interface endpoints 

resource "aws_security_group" "vpc_endpoints" {
  count = (var.enable_ecr_endpoints || var.enable_log_endpoints || var.enable_sts_endpoints) ? 1 : 0

  name        = "${local.name}-vpc-endpoints-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc-endpoints-sg"
  })
}

# =============================================================================
# ECR API VPC ENDPOINT (Interface)
# =============================================================================

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-ecr-api-endpoint"
  })
}

# =============================================================================
# ECR DKR VPC ENDPOINT (Interface - Docker Registry)
# =============================================================================

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-ecr-dkr-endpoint"
  })
}

# =============================================================================
# CLOUDWATCH LOGS VPC ENDPOINT (Interface)
# =============================================================================

resource "aws_vpc_endpoint" "logs" {
  count = var.enable_log_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-logs-endpoint"
  })
}

# =============================================================================
# STS VPC ENDPOINT (Interface - for IRSA)
# =============================================================================

resource "aws_vpc_endpoint" "sts" {
  count = var.enable_sts_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-sts-endpoint"
  })
}