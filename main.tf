# Configure the AWS provider
provider "aws" {
    region = "us-east-2"
}

# Create a security group that allows RDP traffic only from your specified IP address
resource "aws_security_group" "allow_rdp" {
    name        = "allow_rdp_sg"
    description = "Allow RDP access only from yourip"

    ingress {
        from_port   = 3389
        to_port     = 3389
        protocol    = "tcp"
        cidr_blocks = ["yourip/yoursubnet"]
    }

    tags = {
        Name = "RDP Security Group"
    }
}

# Create the Windows Server 2019 EC2 instance with GUI enabled
resource "aws_instance" "windows_server" {
    ami           = "ami-004f67fe399a22169" # AWS-provided Windows Server 2019 image
    instance_type = "t2.micro"              # Free tier eligible instance type

    key_name               = "yourkeyname" # Name of your existing AWS key pair
    vpc_security_group_ids = [aws_security_group.allow_rdp.id]

    tags = {
        Name = "Yourname"
    }
}

# Output the public IP and RDP connection string for easy access
output "instance_public_ip" {
    value       = aws_instance.windows_server.public_ip
    description = "Public IP address of the Windows Server instance"
}

output "rdp_connection_string" {
    value       = "mstsc /v:${aws_instance.windows_server.public_ip}:3389"
    description = "RDP connection string to connect to the instance"
}