resource "google_compute_network" "kthw_network" {
  name = "kubernetes-the-hard-way"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "kthw_subnet" {
    name = "kubernetes"
    network = google_compute_network.kthw_network.self_link
    ip_cidr_range = "10.240.0.0/24"
}

resource "google_compute_firewall" "kthw_internal_firewall" {
    name = "kubernetes-the-hard-way-allow-internal"
    network = google_compute_network.kthw_network.name
    allow {
      protocol = "tcp"
    }
    allow {
      protocol = "icmp"
    }
    allow {
      protocol = "udp"
    }
}

resource "google_compute_firewall" "kthw_external_firewall" {
  name = "kubernetes-the-hard-way-allow-external"
  network = google_compute_network.kthw_network.name
  allow {
    protocol = "tcp"
    ports = ["6443", "22"]
  }
  
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_address" "kthw_external_ip" {
  name = "kubernetes-the-hard-way"
}

resource "google_compute_instance" "controller" {
  name = "controller-${count.index}"
  count = 3
  can_ip_forward = true
  machine_type = "n1-standard-1"
  zone = var.gcp_zone
  tags = ["kubernetes-the-hard-way","controller"]
  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  network_interface {
    subnetwork = google_compute_subnetwork.kthw_subnet.name
    network_ip = "10.240.0.1${count.index}"
    // To get an external IP
    access_config {}
  }

  boot_disk {
    initialize_params {
      size = 200
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }
}

resource "google_compute_instance" "worker" {
  name = "worker-${count.index}"
  count = 3
  can_ip_forward = true
  machine_type = "n1-standard-1"
  zone = var.gcp_zone
  tags = ["kubernetes-the-hard-way","worker"]

  boot_disk {
    initialize_params {
      size = 200
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.kthw_subnet.name
    network_ip = "10.240.0.2${count.index}"

     // To get an external IP
    access_config {}
  }

  service_account {
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }

  metadata = {
    pod-cidr = "10.200.${count.index}.0/24"
  }
}