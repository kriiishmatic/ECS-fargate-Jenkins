variable "project" {
    default = "project-k"
}

variable "environment" {
    default = "dev"
}

variable "zone_name" {
  type        = string
  default     = "project-k.online"
  description = "description"
}

variable "zone_id" {
  type        = string
  default     = "Z031931614KGBZCR4BQA8"
  description = "description"
}

variable "sonar" {
  default = false
}