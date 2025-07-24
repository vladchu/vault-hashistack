variable "aws_region" {
  description = "The region name to deploy into"
  default     = "eu-west-2"
}

variable "aws_key_name" {
  description = "SSH key name"
  default     = "SlavaUkraine"
}

variable "nomad_node_instance_type" {
  description = "EC2 instance type/size for Nomad nodes"
  default     = "t2.micro"
}

variable "nomad_node_ami_id" {
  description = "AMI ID to use for Nomad nodes"
  default     = "ami-0bd2099338bc55e6d"
}

variable "nomad_node_count" {
  description = "The number of server nodes (should be 3 or 5)"
  type        = number
  default     = 1
}

variable "allowed_ip_network" {
  description = "Ip network"
  default     = ["0.0.0.0/0"]
}

variable "az_map" {
  type = map(any)

  default = {
    0 = "a"
    1 = "b"
    2 = "c"
  }
}
