# NATインスタンス
resource "aws_instance" "nat" {
  ami                    = var.nat_ami
  instance_type          = "t4g.nano"
  subnet_id              = aws_subnet.public_1a.id
  vpc_security_group_ids = [aws_security_group.nat.id]
  source_dest_check      = false  # NATインスタンスには必須の設定
  key_name              = aws_key_pair.generated_key.key_name

  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Enable IP forwarding
              echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
              sudo sysctl -p
              # Configure NAT
              sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              # Save iptables rules
              sudo yum install -y iptables-services
              sudo service iptables save
              sudo systemctl enable iptables
              EOF

  tags = {
    Name = "NATInstance"
  }
} 