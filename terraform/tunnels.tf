# Tunnel with tunnel route
resource "cloudflare_tunnel" "lab" {
  account_id = data.cloudflare_accounts.gt_lab.accounts[0].id
  name       = "unraid"
  secret     = base64encode(random_string.lab_tunnel_secret.result)
}

resource "random_string" "lab_tunnel_secret" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "cloudflare_tunnel_route" "lab" {
  account_id         = data.cloudflare_accounts.gt_lab.accounts[0].id
  tunnel_id          = cloudflare_tunnel.lab.id
  network            = "10.10.0.0/16"
  comment            = "Tunnel to unraid docker container"
  virtual_network_id = cloudflare_tunnel_virtual_network.lab.id
}

resource "cloudflare_tunnel_virtual_network" "lab" {
  account_id = data.cloudflare_accounts.gt_lab.accounts[0].id
  name       = "lab"
}

resource "cloudflare_tunnel_config" "lab" {
  account_id = data.cloudflare_accounts.gt_lab.accounts[0].id
  tunnel_id  = cloudflare_tunnel.lab.id
  config {
    warp_routing {
      enabled = true
    }

    ingress_rule {
      service  = "http://10.10.2.1:2368"
      hostname = "george.dev"
    }

    ingress_rule {
      service  = "http://10.10.3.2:8000"
      hostname = "analytics.george.dev"
      origin_request {
        bastion_mode             = false
        disable_chunked_encoding = false
        http2_origin             = false
        keep_alive_connections   = 0
        no_happy_eyeballs        = false
        no_tls_verify            = false
        proxy_port               = 0
        access {
          aud_tag  = []
          required = false
        }
      }
    }

    ingress_rule {
      service  = "http://10.10.1.9:8123"
      hostname = "ha.george.dev"
      origin_request {
        bastion_mode             = false
        disable_chunked_encoding = false
        http2_origin             = false
        keep_alive_connections   = 0
        no_happy_eyeballs        = false
        no_tls_verify            = false
        proxy_port               = 0
        access {
          aud_tag = [
            "e265451746ac2277533450a3022cf9f651dc05901be05fb1c2b86ca0bcbfd249",
          ]
          required  = true
          team_name = "georgetaylor"
        }
      }
    }

    ingress_rule {
      service  = "http://10.10.82.149"
      hostname = "coolify.george.dev"
      origin_request {
        bastion_mode             = false
        disable_chunked_encoding = false
        http2_origin             = false
        keep_alive_connections   = 0
        no_happy_eyeballs        = false
        no_tls_verify            = false
        proxy_port               = 0
        #        access {
        #          aud_tag = [
        #            "b9d7639b037a6921810c5fe8de245bf425bb68cf40124a610d55ba163ded95d9",
        #          ]
        #          required  = true
        #          team_name = "georgetaylor"
        #        }
      }
    }

    ingress_rule {
      service  = "http://10.10.10.10:8080"
      hostname = "track.george.dev"
    }

    ingress_rule {
      service  = "http://10.10.82.149"
      hostname = "shhmas.george.dev"
    }

    ingress_rule {
      service  = "http://10.10.82.149"
      hostname = "shhmas-staging.george.dev"
    }

    ingress_rule {
      service  = "http://10.10.82.149"
      hostname = "*.lab.george.dev"
    }

    ingress_rule {
      service = "http://10.10.2.1:2368"
    }
  }
}

resource "cloudflare_record" "george_dev_ghost" {
  name    = "george.dev"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = cloudflare_tunnel.lab.cname
  zone_id = data.cloudflare_zone.george_dev.id
}


resource "cloudflare_record" "george_dev_analytics" {
  name    = "analytics"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = cloudflare_tunnel.lab.cname
  zone_id = data.cloudflare_zone.george_dev.id
}

resource "cloudflare_record" "george_dev_ha" {
  name    = "ha"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = cloudflare_tunnel.lab.cname
  zone_id = data.cloudflare_zone.george_dev.id
}

resource "cloudflare_record" "george_dev_track" {
  name    = "track"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = cloudflare_tunnel.lab.cname
  zone_id = data.cloudflare_zone.george_dev.id
}


resource "cloudflare_record" "george_dev_shhmas" {
  name    = "shhmas"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = cloudflare_tunnel.lab.cname
  zone_id = data.cloudflare_zone.george_dev.id
}

resource "cloudflare_record" "george_dev_coolify" {
  name    = "coolify"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = cloudflare_tunnel.lab.cname
  zone_id = data.cloudflare_zone.george_dev.id
}

resource "cloudflare_record" "george_dev_shhmas_staging" {
  name    = "shhmas-staging"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = cloudflare_tunnel.lab.cname
  zone_id = data.cloudflare_zone.george_dev.id
}

resource "cloudflare_record" "george_dev_lab" {
  name    = "lab"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = cloudflare_tunnel.lab.cname
  zone_id = data.cloudflare_zone.george_dev.id
}

resource "cloudflare_record" "george_dev_lab_wildcard" {
  name    = "*.lab"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = cloudflare_tunnel.lab.cname
  zone_id = data.cloudflare_zone.george_dev.id
}
