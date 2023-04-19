job "pgsql-msrvc01" {
  datacenters = ["dc1"]
  type = "service"

  update {
    max_parallel      = 3
    stagger           = "60s"
  }

  group "pgsql-msrvc01" {
    count = 2

    
    task "pgsql-msrvc01" {
      driver = "docker"

      config {
        image = "pgsql-patroni:latest"
        hostname = "pgsql-0${NOMAD_ALLOC_INDEX}"
        auth {
          username = "buildagent_ro"
          password = "j5xN6ePdlIDiHiPphvKf9EezoBP4gwj_"
        }

  #      volumes = [
  #          "/var/lib/pgsql/data:/home/pgsql/data"
  #      ]

        port_map {
          patroni = 8008
          pgsql = 5432
          consul = 8500
        }
      }

      env {
        PATRONI_NAME = "pgsql-0${NOMAD_ALLOC_INDEX}"
        PATRONI_POSTGRESQL_CONNECT_ADDRESS = "${NOMAD_ADDR_pgsql}"
        PATRONI_RESTAPI_CONNECT_ADDRESS = "${NOMAD_ADDR_patroni}"
        PATRONI_CONSUL_HOST = "${NOMAD_IP_pgsql}:8500"
        PATRONI_SCOPE = "${NOMAD_JOB_NAME}"
      }

      resources {
        cpu = 4400
        memory = 512
        disk = 1024
        network {
          mbits = 100
          port "patroni" {
            static = "8008"
          }
          port "pgsql" {
          }
        }
      }

      service {
        name = "pgsql-msrvc01"
        port = "pgsql"

      }
      service {
        name = "patroni-pgsql-msrvc01"
        port = "patroni"
      }

    }

  }
}