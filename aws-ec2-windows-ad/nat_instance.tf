resource "aws_instance" "nat" {
  ami                    = "ami-0abcdef1234567890"  # Amazon Linux 2023 (ARM64) AMI IDを指定
  instance_type          = "t4g.nano"
  subnet_id              = aws_subnet.public_1.id  # パブリックサブネットに配置
  vpc_security_group_ids = [aws_security_group.nat.id]
  key_name               = aws_key_pair.generated_key.key_name

  associate_public_ip_address = true  # パブリックIPを割り当て

  user_data = <<-EOF
              #!/bin/bash
              echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
              sysctl -p
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              EOF

  tags = {
    Name = "NATInstance"
  }
}

resource "aws_security_group" "nat" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # SSHアクセスを許可
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # 全てのアウトバウンドトラフィックを許可
  }

  tags = {
    Name = "NATSecurityGroup"
  }
} 