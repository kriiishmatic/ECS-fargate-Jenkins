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
  default     = "Z067018727RH31TLMADD9"
  description = "description"
}

variable "sonar" {
  default = false
}