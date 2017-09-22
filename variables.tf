variable "env" {
  description = "Environment name"
}

variable "platform_config" {
  description = "Platform configuration"
  type        = "map"
  default     = {}
}

variable "release" {
  type        = "map"
  description = "Metadata about the release"
}

variable "common_application_environment" {
  description = "Environment parameters passed to the container for all environments"
  type        = "map"
  default     = {}
}

variable "application_environment" {
  description = "Environment specific parameters passed to the container"
  type        = "map"
  default     = {}
}

variable "secrets" {
  type        = "map"
  description = "Secret credentials fetched using credstash"
  default     = {}
}

variable "dns_domain" {
  type        = "string"
  description = "The DNS domain - unused, pending deletion"
  default     = ""
}

variable "ecs_cluster" {
  type        = "string"
  description = "The ECS cluster"
  default     = "default"
}

variable "port" {
  type        = "string"
  description = "The port that container will be running on"
}

variable "cpu" {
  type        = "string"
  description = "CPU unit reservation for the container"
}

variable "memory" {
  type        = "string"
  description = "The memory reservation for the container in megabytes"
}

variable "alb_listener_arn" {
  type        = "string"
  description = "The Amazon Resource Name for the HTTPS listener on the load balancer"
}

variable "alb_listener_rule_priority" {
  type        = "string"
  description = "The priority for the rule - must be different per rule."
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running."
  type        = "string"
  default     = "3"
}

# optional
variable "path_conditions" {
  description = "Defines path-based conditions for routing; separate by, eg. '/home,/home/*'"
  type        = "list"
  default     = ["*"]
}

variable "host_condition" {
  description = "Defines host-based condition for rule (domain name)"
  type        = "string"
  default     = "*.*"
}

variable "name_suffix" {
  description = "Set a suffix that will be applied to the name in order that a component can have multiple services per environment"
  type        = "string"
  default     = ""
}
