# calling the locals block 

locals {
  istio_charts_url = "https://istio-release.storage.googleapis.com/charts"
}



# Create a namespace for Istio
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}
/*
# Create a namespace for Kiali
resource "kubernetes_namespace" "kiali" {
  metadata {
    name = "kiali"
  }
}

# Create a namespace for Prometheus
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}
*/
# Install Istio base components
resource "helm_release" "istio_base" {
  name            = "istio-base"
  namespace       = kubernetes_namespace.istio_system.metadata[0].name
  chart           = "base"
  repository      = local.istio_charts_url
  cleanup_on_fail = true
  force_update    = false

  depends_on = [kubernetes_namespace.istio_system]
}

# Install Istio discovery (control plane)
resource "helm_release" "istiod" {
  name            = "istiod"
  namespace       = kubernetes_namespace.istio_system.metadata[0].name
  chart           = "istiod"
  repository      = local.istio_charts_url
  version         = "1.22.3" # Specify the Istio version you want to install
  timeout         = 1200
  cleanup_on_fail = true
  force_update    = false

  values = [
    file("${path.module}/istio-values.yaml")
  ]


  depends_on = [helm_release.istio_base]
}

# Install Istio Ingress Gateway
# resource "helm_release" "istio_ingress_gateway" {
#   name       = "istio-ingressgateway"
#   namespace  = kubernetes_namespace.istio_system.metadata[0].name
#   chart      = "gateway"
#   repository = local.istio_charts_url
#   version    = "1.22.3" # Specify the Istio version you want to install
#   timeout    = 800

#   depends_on = [helm_release.istiod]
# }


resource "kubernetes_labels" "example" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = "default"
  }
  labels = {
    istio-injection = "enabled"
  }
}


# Install Prometheus
resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  chart      = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  #version    = "15.2.0" # Specify the Prometheus chart version you want to install
  timeout = 600

  values = [
    file("${path.module}/prometheus-values.yaml")
  ]

  depends_on = [kubernetes_namespace.istio_system]
}

# Install Kiali
resource "helm_release" "kiali" {
  name       = "kiali"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  chart      = "kiali-server"
  repository = "https://kiali.org/helm-charts"
  version    = "1.82.0" # Specify the Kiali chart version you want to install
  timeout    = 1200

  values = [
    file("${path.module}/kiali-values.yaml")
  ]

  depends_on = [kubernetes_namespace.istio_system, helm_release.istiod, helm_release.prometheus]
}

/*
resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  chart      = "Grafana"
  repository = "https://grafana.github.io/helm-charts"
  timeout    = 300
  

   depends_on = [kubernetes_namespace.istio_system, helm_release.prometheus]

}
*/