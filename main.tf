resource "aws_spot_instance_request" "rabbitmq" {
  ami                  = data.aws_ami.ami.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id[0]
  # we are placing the server on private_subnet(db-az1) only. so we are attaching it to index_0 subnet_id.
  wait_for_fulfillment = "true"  # mandatory for spot_instances
  tags                 = {
    merge (var.tags, Name = "${var.env}-rabbitmq")

  vpc_security_group_ids = [aws_security_group.main.id]

  # userdata.sh has to be sent in base64 format
  # the file_userdata.sh will be converted into base64_format using the function "filebase64encode"
  # " ${path.module} " >>  the file_userdata.sh will be searched in the location "p-tf-module-app"
  # " templatefile " >> is another function to replace the variables
  user_data = filebase64encode(templatefile("${path.module}/userdata.sh", {
    component = rabbitmq
    env       = var.env
  })
    }

  iam_instance_profile = aws_iam_instance_profile.main.name
    }

    }


resource "aws_ec2_tag" "example" {
   resource_id = aws_spot_instance_request.rabbitmq.spot_instance_id
   key         = "Name"
   value       = "${var.env}-rabbitmq"
    }


resource "aws_route53_record" "name" {
  zone_id = data.aws_route53_zone.domain.zone_id      # input >> dns_domain = "nellore.online"
  name    = "${var.component}-${var.env}-${var.dns_domain}"              # rabbitmq-dev-nelllore.online
  type    = "A"
  ttl     = 30
  records = aws_spot_instance_request.rabbitmq.private_ip    # hitting from internet with dev.nellore.online >> allowed to access the (Public_LB + Private_LB)
# cname = name to IP
}

#shipping_route >>
#1. NOT-APPLICABLE >> endpoint (create_parameters)
#2. security_group
#3. attach security_group back to rds
#4. iam policy (allowing app_subnet_shipping to access rds )
#5. NOT-APPLICABLE >> schema update with (parameters, username:password)
#6. userdata.sh
#7. iam_instance_profile >> for iam
#8. caller_identity >> for iam


# Security_Group for rabbitmq
resource "aws_security_group" "main" {
  name        = "rabbitmq-${var.env}-sg"
  description = "rabbitmq-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    description      = "SSH"
    from_port        = 22           # we are opening To bastion_cidr
    to_port          = 22           # we are opening opening port 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr     # bastion_node Private_ip is used
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
}

  ingress {
    description      = "RABBITMQ"
    from_port        = 5672           # inside rabbitmq we are opening port 5672
    to_port          = 5672           # inside rabbitmq we are opening port 5672
    protocol         = "tcp"
    cidr_blocks      = var.cidr_block     # here we have to specify which (app)subnet should access the docdb (not in terms of subnet_id, but in terms of cidr_block)
}

tags = {
  merge (var.tags, Name = "rabbitmq-${var.env}-security-group")
}
