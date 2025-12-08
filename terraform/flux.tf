resource "flux_bootstrap_git" "main" {
  path               = var.target_path
  embedded_manifests = true
  components_extra   = ["image-reflector-controller", "image-automation-controller"]
}
