resource "aws_spot_instance_request" "rabbitmq" {
  ami           = data.aws_ami.ami.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id[0]  # we are placing the server on private_subnet(db-az1) only. so we are attaching it to index_0 subnet_id.
  wait_for_fulfillment = "true"  # mandatory for spot_instances
  tags = {
    merge (var.tags, Name = "${var.env}-rabbitmq")

  }
}