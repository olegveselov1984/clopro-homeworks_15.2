# Домашнее задание к занятию «Вычислительные мощности. Балансировщики нагрузки»  

### Подготовка к выполнению задания

1. Домашнее задание состоит из обязательной части, которую нужно выполнить на провайдере Yandex Cloud, и дополнительной части в AWS (выполняется по желанию). 
2. Все домашние задания в блоке 15 связаны друг с другом и в конце представляют пример законченной инфраструктуры.  
3. Все задания нужно выполнить с помощью Terraform. Результатом выполненного домашнего задания будет код в репозитории. 
4. Перед началом работы настройте доступ к облачным ресурсам из Terraform, используя материалы прошлых лекций и домашних заданий.

---
## Задание 1. Yandex Cloud 

**Что нужно сделать**

1. Создать бакет Object Storage и разместить в нём файл с картинкой:

 - Создать бакет в Object Storage с произвольным именем (например, _имя_студента_дата_).
 - Положить в бакет файл с картинкой.
 - Сделать файл доступным из интернета.

```

# Service Accounts sa4bucket

resource "yandex_iam_service_account" "sa4bucket" {
    name      = "sa4bucket"  #создали пользователя
}

resource "yandex_resourcemanager_folder_iam_member" "storage-editor" {
    folder_id = var.folder_id
    role      = "storage.admin"  #роль пользователя 
    member    = "serviceAccount:${yandex_iam_service_account.sa4bucket.id}" #Сообщили что это сервисный акккаунт
}

resource "yandex_iam_service_account_static_access_key" "sa-sa-key" { #сгенерили key для УЗ
    service_account_id = yandex_iam_service_account.sa4bucket.id
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
```


<img width="1391" height="438" alt="image" src="https://github.com/user-attachments/assets/e6010558-4ecb-4370-8d4c-9f04e679ab8c" />

<img width="841" height="294" alt="image" src="https://github.com/user-attachments/assets/b8bae230-2f37-4f44-aea3-11c22fcfa4de" />

<img width="1147" height="372" alt="image" src="https://github.com/user-attachments/assets/4f03d75d-e5ca-4615-90f9-824f45778bc5" />



  
   
2. Создать группу ВМ в public подсети фиксированного размера с шаблоном LAMP и веб-страницей, содержащей ссылку на картинку из бакета:

 - Создать Instance Group с тремя ВМ и шаблоном LAMP. Для LAMP рекомендуется использовать `image_id = fd827b91d99psvq5fjit`.
 - Для создания стартовой веб-страницы рекомендуется использовать раздел `user_data` в [meta_data](https://cloud.yandex.ru/docs/compute/concepts/vm-metadata).
 - Разместить в стартовой веб-странице шаблонной ВМ ссылку на картинку из бакета.
 - Настроить проверку состояния ВМ.

ig.tf
```
resource "yandex_compute_instance_group" "lamp-group" {
  name               = "lamp-group"
  folder_id          = var.folder_id
  service_account_id = yandex_iam_service_account.sa4ig.id 

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
        image_id = "fd827b91d99psvq5fjit" 
        size     = 20
      }
    }

    network_interface {
      subnet_ids =  [module.vpc-dev.subnet_id] 
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

  health_check { # проверка
    http_options {
      port = 80
      path = "/"
    }
  }
}
```


<img width="497" height="407" alt="image" src="https://github.com/user-attachments/assets/da293162-93fb-4571-929e-026224c36256" />

<img width="1404" height="384" alt="image" src="https://github.com/user-attachments/assets/4fcd860b-d1e9-43ff-b1ef-4d66512fe453" />


 
3. Подключить группу к сетевому балансировщику:

 - Создать сетевой балансировщик.
 - Проверить работоспособность, удалив одну или несколько ВМ.
4. (дополнительно)* Создать Application Load Balancer с использованием Instance group и проверкой состояния.

load-balancer.tf
```
# Target Group: создаём entry с адресами всех инстансов из группы
resource "yandex_lb_target_group" "lamp_tg" {
  name      = "lamp-tg"
  folder_id = var.folder_id

  dynamic "target" {
    for_each = yandex_compute_instance_group.lamp-group.instances
    content {
      subnet_id = module.vpc-dev.subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }

}

# Network Load Balancer
resource "yandex_lb_network_load_balancer" "nlb" {
  name = "lamp-nlb"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {}
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lamp_tg.id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

```

<img width="926" height="320" alt="image" src="https://github.com/user-attachments/assets/44772f6b-9295-4601-8a24-7ff85e8f7d97" />
<img width="496" height="399" alt="image" src="https://github.com/user-attachments/assets/11b247f9-fc09-4123-9fb3-cc928a8a11f9" />


Остановили 2 ВМ:

<img width="1814" height="386" alt="image" src="https://github.com/user-attachments/assets/5c6ef1d9-84ab-4a39-a9b0-0a5e13627189" />
<img width="709" height="1161" alt="image" src="https://github.com/user-attachments/assets/7cb6861e-5a3c-4eee-9c0f-27b9bbe706e7" />

Сайт доступен

<img width="514" height="435" alt="image" src="https://github.com/user-attachments/assets/111d229f-871c-4fcb-b863-351d22fdc53c" />




Полезные документы:

- [Compute instance group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance_group).
- [Network Load Balancer](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_network_load_balancer).
- [Группа ВМ с сетевым балансировщиком](https://cloud.yandex.ru/docs/compute/operations/instance-groups/create-with-balancer).

---
## Задание 2*. AWS (задание со звёздочкой)

Это необязательное задание. Его выполнение не влияет на получение зачёта по домашней работе.

**Что нужно сделать**

Используя конфигурации, выполненные в домашнем задании из предыдущего занятия, добавить к Production like сети Autoscaling group из трёх EC2-инстансов с  автоматической установкой веб-сервера в private домен.

1. Создать бакет S3 и разместить в нём файл с картинкой:

 - Создать бакет в S3 с произвольным именем (например, _имя_студента_дата_).
 - Положить в бакет файл с картинкой.
 - Сделать доступным из интернета.
2. Сделать Launch configurations с использованием bootstrap-скрипта с созданием веб-страницы, на которой будет ссылка на картинку в S3. 
3. Загрузить три ЕС2-инстанса и настроить LB с помощью Autoscaling Group.

Resource Terraform:

- [S3 bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Launch Template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template).
- [Autoscaling group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group).
- [Launch configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration).

Пример bootstrap-скрипта:

```
#!/bin/bash
yum install httpd -y
service httpd start
chkconfig httpd on
cd /var/www/html
echo "<html><h1>My cool web-server</h1></html>" > index.html
```
### Правила приёма работы

Домашняя работа оформляется в своём Git репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.
