variable "cidr-block-vpc" {
    type = string
	default = "10.20.0.0/16"
}

variable "azs" {
	default = "us-east-1a"
}

variable "cidr-block-route_tb" {
    type = string
    default = "0.0.0.0/0"
}

variable "name-tag" {
    type = string
    default = "_YVN"
}

variable "owner-tag" {
    type = string
    default = "rbakunts"
}

variable "project-tag" {
    type = string
    default = "2024_t2_YVN"
}

variable "instance-type" {
    type = string
    default = "t2.micro"
}