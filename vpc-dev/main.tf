#создаем облачную сеть
resource "yandex_vpc_network" "develop" {
  name = var.env_name_network #"develop"
 }

#создаем подсеть
resource "yandex_vpc_subnet" "develop" {
  name           = var.env_name_subnet #"develop-ru-central1-a"
  zone           = var.zone #"ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = var.cidr 
 }

# #создаем подсеть 2
# resource "yandex_vpc_subnet" "private" {
#   name           = var.env_name_subnet2 #"develop-ru-central1-a"
#   zone           = var.zone2 #"ru-central1-a"
#   network_id     = yandex_vpc_network.develop.id
#   v4_cidr_blocks = var.cidr2
#   route_table_id = var.route_table_id
#  }