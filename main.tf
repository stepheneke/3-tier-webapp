# The main configuratiion file for lab to configure and deploy an Amazon VPC for a 3-tier Web App

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

#Create instance profile role for EC2 instance
resource "aws_iam_role" "IAMInstanceProfileRole" {
    name =  "IAMInstanceProfileRole"
    assume_role_policy = jsonencode ({
    Version: "2012-10-17",
    Statement: [
        {
            Effect: "Allow",
            Action: [
                "sts:AssumeRole"
            ],
            Principal: {
                Service: [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
    })
}

#Attach S3FullAccess permission EC2 instance role
resource "aws_iam_role_policy_attachment" "s3fullaccessattach" {
    role = aws_iam_role.IAMInstanceProfileRole.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#Attach RDSreadonly permission to EC2 instance role
resource "aws_iam_role_policy_attachment" "rdsreadonlyattach" {
    role = aws_iam_role.IAMInstanceProfileRole.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

#Create EC2 instance profile
resource "aws_iam_instance_profile" "IAMinstanceprofile" {
    name = "IAMinstanceprofile"
    role =  aws_iam_role.IAMInstanceProfileRole.name  
}

#Create RDS database subnet group
resource "aws_db_subnet_group" "LabVPCRDSsubnetgroup" {
    name       = "labvpcrdssubnetgroup"
    subnet_ids = [aws_subnet.PrivateSubnet3.id, aws_subnet.PrivateSubnet4.id]
    description = "Subnet group for RDS"
    tags = {
        Name = "labvpcrdssubnetgroup"
    }
}

#Create RDS Amazon Aurora cluster
resource "aws_rds_cluster" "LabVPCDBCluster" {
    cluster_identifier = "labvpcdbcluster"
    engine = "aurora-mysql"
    engine_version = "5.7.mysql_aurora.2.07.2"
    db_subnet_group_name = aws_db_subnet_group.LabVPCRDSsubnetgroup.name
    database_name = "Population"
    master_username = "admin"
    master_password = "testingrdscluster"
    vpc_security_group_ids = [aws_security_group.LabVPCRDSSG.id]
    apply_immediately = true
    skip_final_snapshot = true
}

#Create RDS Amazon Aurora cluster instance - Multi AZ
resource "aws_rds_cluster_instance" "LabVPCDBInstances" {
    count = 2
    identifier = "labvpcdbcluster-${count.index}"
    cluster_identifier = aws_rds_cluster.LabVPCDBCluster.id 
    engine = aws_rds_cluster.LabVPCDBCluster.engine
    engine_version = aws_rds_cluster.LabVPCDBCluster.engine_version
    instance_class = "db.t3.small"
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.LabVPCRDSsubnetgroup.name
} 

#Retrieve the latest amazon linux 2 AMI in the current region
data "aws_ami" "amazon-linux2" {
  owners = [ "amazon" ]
  most_recent = true
  filter {
    name = "name"
    values = [ "amzn2-ami-kernel-*" ]
  }
}

#Create Launch template 
resource "aws_launch_template" "LabVPCEC2Template" {
    name = "labvpcec2template"
    description = "Template to launch EC2 instance and deploy the application"
    image_id = data.aws_ami.amazon-linux2.id
    instance_type = var.instancetype
    depends_on = [aws_rds_cluster.LabVPCDBCluster, aws_rds_cluster_instance.LabVPCDBInstances]
    vpc_security_group_ids = [aws_security_group.LabVPCEC2SG.id]
    iam_instance_profile {
        arn = aws_iam_instance_profile.IAMinstanceprofile.arn
    }
    user_data = filebase64("installwebapp.sh")
}

#Create Auto scaling group
resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [ aws_subnet.PrivateSubnet1.id, aws_subnet.PrivateSubnet2.id  ]
  desired_capacity   = 3
  max_size           = 3
  min_size           = 1
  health_check_type = "ELB"
  health_check_grace_period = 300
  target_group_arns = [aws_lb_target_group.LabVPCALBTargetGroup.arn]
  launch_template {
    id      = aws_launch_template.LabVPCEC2Template.id
    version = "$Latest"
  }
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}

#Create Auto scaling attachment
resource "aws_autoscaling_attachment" "LabVCPALBAutoScalingAttach" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  alb_target_group_arn = aws_lb_target_group.LabVPCALBTargetGroup.arn
}


#Create Application load balancer 
resource "aws_lb" "LabVPCALB" {
    name = "LabVPCALB"
    load_balancer_type = "application"
    security_groups = [aws_security_group.LabVPCALBSG.id]
    internal = false
    ip_address_type = "ipv4"
    subnets = [ aws_subnet.PublicSubnet1.id, aws_subnet.PublicSubnet2.id ] 
}

#Create application load balancer listener
resource "aws_lb_listener" "front_end" {
    load_balancer_arn = aws_lb.LabVPCALB.arn
    port =  "80"
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.LabVPCALBTargetGroup.arn
        
    }
}

#Create application load balancer target group
resource "aws_lb_target_group" "LabVPCALBTargetGroup" {
    name = "labvpcalbtargetgroup"
    port = 8443
    protocol = "HTTP"
    vpc_id = aws_vpc.LabVPC.id
    target_type = "instance"
    health_check {
      matcher = "200"
      path = "/"
      interval = 10
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
    stickiness {
      type = "lb_cookie"
      cookie_duration = 120
    }
}


# Display the load balancer DNS name
output "alb_dns_name" {
    value = "DNS name of the Applicaton Load Balancer ${aws_lb.LabVPCALB.dns_name}"
}