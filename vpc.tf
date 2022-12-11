#Create the VPC
resource "aws_vpc" "LabVPC" {
    cidr_block = var.LabVPCCIDR
    tags = {
        Name = var.VPCName
    }
}

#Creating the subnets: 2 public subnets and 4 private subnets
resource "aws_subnet" "PublicSubnet1" {
    vpc_id = aws_vpc.LabVPC.id
    cidr_block = var.PublicSubnet1_CIDR
    availability_zone = "us-east-1a"
    tags = {
        Name = "PublicSubnet1"
    }
}

resource "aws_subnet" "PublicSubnet2" {
    vpc_id = aws_vpc.LabVPC.id
    cidr_block = var.PublicSubnet2_CIDR
    availability_zone = "us-east-1b"
    tags = {
        Name = "PublicSubnet2"
    }
}

resource "aws_subnet" "PrivateSubnet1" {
    vpc_id = aws_vpc.LabVPC.id
    cidr_block = var.PrivateSubnet1_CIDR
    availability_zone = "us-east-1a"
    tags = {
        Name = "PrivateSubnet1"
    }
}

resource "aws_subnet" "PrivateSubnet2" {
    vpc_id = aws_vpc.LabVPC.id
    cidr_block = var.PrivateSubnet2_CIDR
    availability_zone = "us-east-1b"
    tags = {
        Name = "PrivateSubnet2"
    }
}

resource "aws_subnet" "PrivateSubnet3" {
    vpc_id = aws_vpc.LabVPC.id
    cidr_block = var.PrivateSubnet3_CIDR
    availability_zone = "us-east-1a"
    tags = {
        Name = "PrivateSubnet3"
    }
}

resource "aws_subnet" "PrivateSubnet4" {
    vpc_id = aws_vpc.LabVPC.id
    cidr_block = var.PrivateSubnet4_CIDR
    availability_zone = "us-east-1b"
    tags = {
        Name = "PrivateSubnet4"
    }
}

#Create internet gateway for the public subnets
resource "aws_internet_gateway" "LabVPCInternetGateway" {
    vpc_id = aws_vpc.LabVPC.id
    tags = {
        Name = var.igw
    }
}

#Create NAT gateway 1
resource "aws_nat_gateway" "LabVPCNATGateway" {
    allocation_id = aws_eip.LabEIP.id
    depends_on = [aws_internet_gateway.LabVPCInternetGateway, aws_eip.LabEIP]
    subnet_id = aws_subnet.PublicSubnet1.id
    tags = {
        Name = var.nat_gw
    }
}

#Create Elastic IP for NAT Gateway 1
resource "aws_eip" "LabEIP" {
    vpc = true
    tags = {
        Name = var.eip
    }
} 

#Create NAT gateway 2
resource "aws_nat_gateway" "LabVPCNATGateway2" {
    allocation_id = aws_eip.LabEIP2.id
    depends_on = [aws_internet_gateway.LabVPCInternetGateway, aws_eip.LabEIP2]
    subnet_id = aws_subnet.PublicSubnet2.id
    tags = {
        Name = var.nat_gw2
    }
}

#Create Elastic IP for NAT Gateway 2
resource "aws_eip" "LabEIP2" {
    vpc = true
    tags = {
        Name = var.eip2
    }
} 

#Create Public Route Table 
resource "aws_route_table" "PublicRouteTable" {
    vpc_id = aws_vpc.LabVPC.id
    route {
            cidr_block = var.all_IPs
            gateway_id = aws_internet_gateway.LabVPCInternetGateway.id
        }
    tags = {
        Name = "PublicRouteTable"
    }
}

#Associate PublicSubnet1 and PublicSubnet2 with Public Route Table
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.PublicSubnet1.id
    route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route_table_association" "b" {
    subnet_id = aws_subnet.PublicSubnet2.id
    route_table_id = aws_route_table.PublicRouteTable.id
}

#Create Private Route Table 
resource "aws_route_table" "PrivateRouteTable" {
    vpc_id = aws_vpc.LabVPC.id
    #
    route {
            cidr_block = var.all_IPs
            gateway_id = aws_nat_gateway.LabVPCNATGateway.id
        }
    tags = {
        Name = "PrivateRouteTable"
    }
}

#Associate PrivateSubnet1 with Private Route Table
resource "aws_route_table_association" "c" {
    subnet_id = aws_subnet.PrivateSubnet1.id
    route_table_id = aws_route_table.PrivateRouteTable.id
}

#Associate PrivateSubnet2 with Private Route Table
resource "aws_route_table_association" "d" {
    subnet_id = aws_subnet.PrivateSubnet2.id
    route_table_id = aws_route_table.PrivateRouteTable.id
}

#Associate PrivateSubnet3 with Private Route Table
resource "aws_route_table_association" "e" {
    subnet_id = aws_subnet.PrivateSubnet3.id
    route_table_id = aws_route_table.PrivateRouteTable.id
}

#Associate PrivateSubnet4 with Private Route Table
resource "aws_route_table_association" "f" {
    subnet_id = aws_subnet.PrivateSubnet4.id
    route_table_id = aws_route_table.PrivateRouteTable.id
}

#Create security group for application load balancer
resource "aws_security_group" "LabVPCALBSG" {
    name = "Project-ALB-SG"
    description = "Allows web access"
    vpc_id = aws_vpc.LabVPC.id
    
    ingress {
            description = "Allow traffic from everywhere"
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Project-ALB-SG"
    }
}


#Create security group for EC2 instances
resource "aws_security_group" "LabVPCEC2SG" {
    name = "Project-EC2-SG"
    description = "Allows ALB to access the EC2 instances"
    vpc_id = aws_vpc.LabVPC.id
    
    ingress {
            description = "Allow port 80 traffic from ALB"
            from_port = 80
            to_port = 80
            protocol = "tcp"
            security_groups = [aws_security_group.LabVPCALBSG.id]
    }
    ingress {
            description = "Allow port 8443 traffic from ALB"
            from_port = 8443
            to_port = 8443
            protocol = "tcp"
            security_groups = [aws_security_group.LabVPCALBSG.id]
    }

    egress {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Project-EC2-SG"
    }
}

#Create security group for RDS database instances
resource "aws_security_group" "LabVPCRDSSG" {
    name = "Project-RDS-SG"
    description = "Allows application to access the RDS instances"
    vpc_id = aws_vpc.LabVPC.id
    
    ingress {
            description = "Allow port 3306 traffic from EC2 instances"
            from_port = 3306
            to_port = 3306
            protocol = "tcp"
            security_groups = [aws_security_group.LabVPCEC2SG.id]
    }

    egress {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Project-RDS-SG"
    }
}
