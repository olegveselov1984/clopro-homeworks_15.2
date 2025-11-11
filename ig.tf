resource "yandex_compute_instance_group" "lamp-group" {
  name               = "lamp-group"
  folder_id          = var.folder_id
  service_account_id = yandex_iam_service_account.sa4ig.id #var.service_account_id

  instance_template {
    platform_id = "standard-v1"

    resources {
      cores  = 2
      memory = 2
      core_fraction = 20   # Доля CPU
    }
    scheduling_policy {
    preemptible = true # Прерываемая - Да
    }
    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit" #var.image_lamp
        size     = 20
      }
    }

    network_interface {
      subnet_ids =  [module.vpc-dev.subnet_id] # [yandex_vpc_subnet.develop.id]  # [yandex_vpc_subnet.public.id]
      nat        = true
    }

    metadata = {
      # user-data формирует простую страницу с картинкой из бакета
      user-data = <<-EOT
        #!/bin/bash
        apt-get update -y || true
        apt-get install -y apache2 curl || true
        mkdir -p /var/www/html
        cat > /var/www/html/index.html <<'HTML'
        <!doctype html>
        <html>
        <head><meta charset="utf-8"><title>LAMP group</title></head>
        <body>
        <h1>Hello from Instance Group</h1>
        <p>Image from Object Storage:</p>
        <img src="http://storage.yandexcloud.net/pictures-bucket/pic-bucket.jpg"/>
        </body>
        </html>
        HTML
        systemctl enable apache2
        systemctl restart apache2
      EOT
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [var.default_zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }

  health_check {  # проверка
    http_options {
      port = 80
      path = "/"
    }
  }
}