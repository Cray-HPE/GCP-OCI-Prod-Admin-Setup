/**
 * Copyright 2022 The Sigstore Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Private network
// Forked from https://github.com/GoogleCloudPlatform/gke-private-cluster-demo/blob/master/terraform/network.tf

// Enable required services for this module
resource "google_project_service" "service" {
  for_each = toset([
    "compute.googleapis.com", // For compute network, router, firewall. roles/compute.networkAdmin, roles/compute.securityAdmin
  ])
  project = var.project_id
  service = each.key

  // Do not disable the service on destroy. On destroy, we are going to
  // destroy the project, but we need the APIs available to destroy the
  // underlying resources.
  disable_on_destroy = false
}

// Create an external NAT IP
resource "google_compute_address" "nat" {
  name    = format("%s-nat-ip", var.cluster_name)
  project = var.project_id
  region  = var.region

  depends_on = [google_project_service.service]
}

// Create a cloud router for use by the Cloud NAT
resource "google_compute_router" "router" {
  name    = format("%s-cloud-router", var.cluster_name)
  project = var.project_id
  region  = var.region
  network = var.network_self_link

  bgp {
    asn = 64514
  }
}

// Create a NAT router so the nodes can reach DockerHub, etc
resource "google_compute_router_nat" "nat" {
  name    = format("%s-cloud-nat", var.cluster_name)
  project = var.project_id
  router  = google_compute_router.router.name
  region  = var.region

  nat_ip_allocate_option = "MANUAL_ONLY"

  nat_ips = [google_compute_address.nat.self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = var.subnetwork_self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]

    secondary_ip_range_names = [
      var.secondary_ip_range_name_pod,
      var.secondary_ip_range_name_svc
    ]
  }
}
