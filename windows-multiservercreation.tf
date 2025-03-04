# Configure the AWS provider
provider "aws" {
    region = "us-east-2" #change this to whichever reason is clos to you
}

# Create a VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name        = "my-windows-vpc"
        Environment = "dev"
    }
}

# Create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
}

# Create a route table for the VPC and associate it with the subnet
resource "aws_route_table" "main" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "Main Route Table"
    }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "main" {
    subnet_id      = aws_subnet.main.id
    route_table_id = aws_route_table.main.id
}

# Create a subnet within the VPC
resource "aws_subnet" "main" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.1.0/24" #put any private range you would want
    availability_zone = "us-east-2a"
    map_public_ip_on_launch = true   # This enables auto-assignment of public IPs

    tags = {
        Name = "Main Subnet"
    }
}

# Create a security group that allows RDP remoting
resource "aws_security_group" "windows_access" {
    name         = "windows_access_sg"
    description  = "Allow RDP remoting access"
    vpc_id       = aws_vpc.main.id

    # Allow RDP access from all sources (0.0.0.0/0 for testing)
    ingress {
        from_port    = 3389
        to_port      = 3389
        protocol     = "tcp"
        cidr_blocks  = ["0.0.0.0/0"]  # Change this to your specific IP later
        description  = "RDP access"
    }
    
    # Allow all traffic between instances in this security group
    ingress {
        from_port    = 0
        to_port      = 0
        protocol     = "-1"
        self         = true
        description  = "Allow all traffic between instances in this security group"
    }

    # Allow all outbound traffic
    egress {
        from_port    = 0
        to_port      = 0
        protocol     = "-1"
        cidr_blocks  = ["0.0.0.0/0"]
        description  = "Allow all outbound traffic"
    }

    tags = {
        Name = "Windows Server Access Security Group"
    }
}

# Define the servers
locals {
    servers = {
        server1 = "server1"
        server2 = "server2"
    }
}

# Create the Windows Server instances
resource "aws_instance" "windows_server" {  
    for_each       = local.servers
    ami            = "ami-004f67fe399a22169"  # Windows Server 2019 AMI in us-east-2
    instance_type  = "t3.micro"               
    key_name       = "your keyname"         # Replace with your actual key pair name
    vpc_security_group_ids = [aws_security_group.windows_access.id]
    subnet_id      = aws_subnet.main.id
    associate_public_ip_address = true        # Explicitly associate public IP addresses

    tags = {
        Name = each.value
    }
}

# Output the public IPs and connection strings for both servers
output "server_details" {
    value = {
        for k, instance in aws_instance.windows_server : k => { 
            public_ip     = instance.public_ip
            name          = instance.tags["Name"]
            rdp_connection = "mstsc /v:${instance.public_ip}:3389"
        }
    }
    description = "Connection details for all Windows Server instances"
}
