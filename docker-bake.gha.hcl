variable "cache-from" {
  default = ["type=gha"]
}

variable "cache-to" {
  default = ["type=gha,mode=max"]
}
