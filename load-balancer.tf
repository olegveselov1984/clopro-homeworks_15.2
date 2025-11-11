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

# # Output: собираем все внешние адреса listener'ов (если их несколько)
# output "nlb_ip" {
#   value = flatten([
#     for l in yandex_lb_network_load_balancer.nlb.listener :
#     [ for spec in l.external_address_spec : spec.address ]
#   ])
# }