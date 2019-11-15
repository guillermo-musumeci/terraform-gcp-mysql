# Terraform plugin for creating random ids
resource "random_id" "instance_id" {
 byte_length = 4
}

# create My SQL database instance
resource "google_sql_database_instance" "my_sql" {
  name                 = "${var.app_name}-${var.app_environment}-db-${random_id.instance_id.hex}"
  project              = "${var.app_project}"
  region               = "${var.gcp_region_1}"
  database_version     = "${var.db_version}"
  
  settings {
    tier = "${var.db_tier}"
    activation_policy           = "${var.db_activation_policy}"
    disk_autoresize             = "${var.db_disk_autoresize}"
    disk_size                   = "${var.db_disk_size}"
    disk_type                   = "${var.db_disk_type}"
    pricing_plan                = "${var.db_pricing_plan}"
    
    location_preference {
      zone = "${var.gcp_zone_1}"
    }

    maintenance_window {
      day  = "7"  # sunday
      hour = "3" # 3am  
    }

    database_flags {
      name  = "log_bin_trust_function_creators"
      value = "on"
    }

    backup_configuration {
      binary_log_enabled = true
      enabled            = true
      start_time         = "00:00"
    }

    ip_configuration {
      ipv4_enabled = "true"
      authorized_networks {
        value = "${var.db_instance_access_cidr}"
      }
    }
  }
}

# create database
resource "google_sql_database" "my_sql_db" {
  name      = "${var.db_name}"
  project   = "${var.app_project}"
  instance  = "${google_sql_database_instance.my_sql.name}"
  charset   = "${var.db_charset}"
  collation = "${var.db_collation}"
}

# create user
resource "random_id" "user_password" {
  byte_length = 8
}

resource "google_sql_user" "my-sql" {
  name     = "${var.db_user_name}"
  project  = "${var.app_project}"
  instance = "${google_sql_database_instance.my_sql.name}"
  host     = "${var.db_user_host}"
  password = "${var.db_user_password == "" ? random_id.user_password.hex : var.db_user_password}"
}
