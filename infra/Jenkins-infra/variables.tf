variable "project" {
    default = "stackly"
}

variable "environment" {
    default = "dev"
}

variable "zone_name" {
  type        = string
  default     = "kriiishmatic.fun"
  description = "description"
}

variable "zone_id" {
  type        = string
  default     = "Z05462863CHYUYES9E9C8"
  description = "description"
}

variable "sonar" {
  default = false
}