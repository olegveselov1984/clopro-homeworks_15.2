module "vpc-dev" {  #название модуля
  source       = "./vpc-dev" 
  env_name_network = "VPC" #параметры которые передаем
  env_name_subnet  = "public" #параметры которые передаем
  zone = "ru-central1-a"
  cidr = ["192.168.10.0/24"]
#   zone2 = "ru-central1-a"
#   env_name_subnet2  = "private" #параметры которые передаем
#   cidr2 = ["192.168.20.0/24"]
#  route_table_id = yandex_vpc_route_table.private_routes.id
}

# resource "yandex_vpc_route_table" "private_routes" {  #создание роутера (NAT-инстанс)
#   name       = "private-route-table"
#   network_id = module.vpc-dev.network_id   #yandex_vpc_network.default.id

#   static_route {
#     destination_prefix = "0.0.0.0/0"
#     next_hop_address   = "192.168.10.254"
#   }
# }

# Service Accounts sa4bucket

resource "yandex_iam_service_account" "sa4bucket" {
    name      = "sa4bucket"  #создали пользователя
}

resource "yandex_resourcemanager_folder_iam_member" "storage-editor" {
    folder_id = var.folder_id
    role      = "storage.admin"  #роль пользователя 
    member    = "serviceAccount:${yandex_iam_service_account.sa4bucket.id}" #Сообщили что это сервисный акккаунт
#    depends_on = [yandex_iam_service_account.sa4bucket]
}


resource "yandex_iam_service_account_static_access_key" "sa-sa-key" { #сгенерили key для УЗ
    service_account_id = yandex_iam_service_account.sa4bucket.id
    # description        = "access key for bucket"
}

# Service Accounts sa4ig

resource "yandex_iam_service_account" "sa4ig" {
    name      = "sa4ig"
}

resource "yandex_resourcemanager_folder_iam_member" "ig-editor" {
    folder_id = var.folder_id
    role      = "editor"
    member    = "serviceAccount:${yandex_iam_service_account.sa4ig.id}"
}


# Object Storage + Bucket

resource "yandex_storage_bucket" "pictures-bucket" {
    depends_on = [ yandex_iam_service_account.sa4bucket ]
    access_key = yandex_iam_service_account_static_access_key.sa-sa-key.access_key
    secret_key = yandex_iam_service_account_static_access_key.sa-sa-key.secret_key
    bucket = "pictures-bucket"
    acl    = "public-read"  # публичное хранилище
    max_size   = 1048576
}


resource "yandex_storage_object" "pictures" {
    depends_on = [ yandex_iam_service_account.sa4bucket ]
    access_key = yandex_iam_service_account_static_access_key.sa-sa-key.access_key
    secret_key = yandex_iam_service_account_static_access_key.sa-sa-key.secret_key
    bucket = yandex_storage_bucket.pictures-bucket.bucket
    key = "pic-bucket.jpg"
    source = "./pic.jpg"
    acl    = "public-read"
}


# resource "yandex_compute_instance" "nat" {
#   name = "nat"
#   resources {
#     cores  = 2
#     memory = 2
#   }
#   boot_disk {
#     initialize_params {
#       image_id = "fd80mrhj8fl2oe87o4e1"
#     }
#   }
#   network_interface {
#     subnet_id = module.vpc-dev.subnet_id #module.vpc-dev.subnet_id #yandex_vpc_subnet.public.id
#     ip_address = "192.168.10.254"
#     nat       = true
#   }
#   metadata = {
#     user-data          = data.template_file.cloudinit.rendered 
#     serial-port-enable = 1
#   }
# }




resource "yandex_compute_instance" "public" {
  name = "public"
  scheduling_policy {
    preemptible = true # Прерываемая - Да
  }
  resources {
    cores  = 2
    memory = 2
    core_fraction = 20   # Доля CPU
  }
  boot_disk {
    initialize_params {
      image_id = "fd8ondkh1s6iakbqm635"
    }
  }
  network_interface {
    subnet_id = module.vpc-dev.subnet_id #module.vpc-dev.subnet_id #yandex_vpc_subnet.public.id
    nat       = true
  }
  metadata = {
    user-data          = data.template_file.cloudinit.rendered 
    serial-port-enable = 1
  }
}

# resource "yandex_compute_instance" "private" {
#   name = "private"
#   resources {
#     cores  = 2
#     memory = 2
#   }
#   boot_disk {
#     initialize_params {
#       image_id = "fd8ondkh1s6iakbqm635"
#     }
#   }
#   network_interface {
#     subnet_id = module.vpc-dev.private_id #module.vpc-dev.subnet_id #yandex_vpc_subnet.public.id
#   #  nat       = true
#   }
#   metadata = {
#     user-data          = data.template_file.cloudinit.rendered 
#     serial-port-enable = 1
#   }
# }




#Пример передачи cloud-config в ВМ.(передали путь к yml файлу и переменную!_ssh_public_key)
data "template_file" "cloudinit" {
 template = file("./cloud-init.yml")
   vars = {
     ssh_public_key = var.ssh_public_key
   }
}

