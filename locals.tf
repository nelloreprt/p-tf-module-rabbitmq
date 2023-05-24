locals {
  parameters = [ var.component ]
  # var.parameters >> is not required because rabbitmq is not a db and, rabbit mq will not access any database
  # but rabbitmq will be accessed by bastion node >> the same is mentioned in security_group

  # var.parameters >> we are controlling components on which component is allowed to access which parameters from input_file(main.tfvars)
  # concat >> to combine two lists
}
