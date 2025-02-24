# Configure the AWS provider
provider "aws" {
    region = "us-east-2"
}

# Create a security group that allows RDP remoting
resource "aws_security_group" "windows_access" {
    name        = "windows_access_sg"
    description = "Allow RDP remoting access"
    
    # RDP access
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all inbound traffic"
    }
    
    # Allow all outbound traffic
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }
    
    tags = {
        Name = "Windows Server Access Security Group"
    }
}

# Define the servers
locals {
    servers = {
        server1 = "yourserver-name" #put your servers name here
        server2 = "Yourserver-name2"
    }
}

# Create the Windows Server instances
resource "aws_instance" "windows_server" {
    for_each      = local.servers
    ami           = "ami-004f67fe399a22169"
    instance_type = "t2.micro"
    key_name               = "windows server"
    vpc_security_group_ids = [aws_security_group.windows_access.id]
    subnet_id             = "yoursubnet"  # Assign both servers to the same subnet
    tags = {
        Name = each.value
    }
}

# Output the public IPs and connection strings for both servers
output "server_details" {
    value = {
        for k, instance in aws_instance.windows_server : k => {
            public_ip = instance.public_ip
            name      = instance.tags["Name"]
            rdp_connection = "mstsc /v:${instance.public_ip}:3389"
        }
    }
    description = "Connection details for all Windows Server instances"
}
