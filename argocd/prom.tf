# Define providers
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "prometheus" {
  name = "prometheus"
  #namespace  = argocd
  chart      = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"

}
resource "helm_release" "grafana" {
  name = "grafana"
  # namespace  = argocd
  chart      = "Grafana"
  repository = "https://grafana.github.io/helm-charts"
  timeout    = 300



}