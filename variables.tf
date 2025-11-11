###cloud vars

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "ssh_public_key" {
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJzqKwUDlLQy+gsAc6as6WUmctThf3uqdlHZPSRwn4OF ed25519 256-20250602"
}

variable "hostname" {
  type        = string
 }

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
  }

  variable "preemptible" {
  type = bool
  default = true
  }

  variable "core_fraction" {
  type    = number
  default = 5
}

# #Set bucket name as name plus date
# locals {
#     date = timestamp()
#     cur_date = formatdate("DD-MM-YYYY", local.date)
#     bucket_name = "baykovms-${local.cur_date}"
# }