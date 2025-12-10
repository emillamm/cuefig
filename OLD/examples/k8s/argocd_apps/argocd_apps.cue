// Example: ArgoCD Application manifests
// These would live in a separate repo (like konfekt-root)

package argocd_apps

import (
	"github.com/emillamm/templates/templates/k8s"
)

// =============================================================================
// ArgoCD Applications
// =============================================================================

autherApp: (k8s.#argocdApp & {
	name:    "auther"
	repoURL: "git@github.com:konfekt-app/auther.git"
}).manifest

routerApp: (k8s.#argocdApp & {
	name:    "router"
	repoURL: "git@github.com:konfekt-app/router.git"
}).manifest

// Export all apps
argoApps: [autherApp, routerApp]
