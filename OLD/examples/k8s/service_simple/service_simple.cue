// Example: Simple Go service without database (like router)
// Generates: Namespace, Rollout, Service

package service_simple

import (
	"github.com/emillamm/templates/templates/k8s"
)

// Configuration
_name:      "router"
_namespace: _name
_image:     "us-east1-docker.pkg.dev/konfekt/konfekt/router:0.0.7-3f64d8a"

// =============================================================================
// Manifests
// =============================================================================

routerNamespace: (k8s.#namespace & {name: _namespace}).manifest

routerRollout: (k8s.#rollout & {
	name:      _name
	namespace: _namespace
	containers: [
		(k8s.#container & {
			name:  _name
			image: _image
		}).spec,
	]
}).manifest

routerService: (k8s.#service & {
	name:      _name
	namespace: _namespace
}).manifest

// Export all manifests as a list
routerManifests: [routerNamespace, routerRollout, routerService]
