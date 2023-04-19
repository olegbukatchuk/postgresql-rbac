job "haproxy" {
  datacenters = ["dc1"]
  type = "service"

  update {
    max_parallel      = 2
    stagger           = "60s"
  }

  group "haproxy" {
    count = 1
    
    task "haproxy" {
      driver = "docker"

      config {
        image = "haproxy:latest"
        hostname = "haproxy-pgsql-${NOMAD_ALLOC_INDEX}"
        auth {
          username = "buildagent_ro"
          password = "j5xN6ePdlIDiHiPphvKf9EezoBP4gwj_"
        }
        port_map {
          happgsqlmsrvc01 = 5010

        }
      }
      resources {
        cpu = 4400
        memory = 512
        disk = 1024
        network {
          port "happgsqlmsrvc01" {
            static = "5010"
          }
        }
      }

    }
  }

}