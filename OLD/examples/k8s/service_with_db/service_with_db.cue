// Example: Go service with Spanner database and migrations (like auther)
// Generates: Namespace, ServiceAccount, Migration Job, Rollout, Service

package service_with_db

import (
	"list"
	corev1 "k8s.io/api/core/v1"
	"github.com/emillamm/templates/templates/k8s"
)

// Configuration
_name:         "auther"
_namespace:    _name
_image:        "us-east1-docker.pkg.dev/konfekt/konfekt/auther-service:0.0.16-2326f7d"
_migrateImage: "us-east1-docker.pkg.dev/konfekt/konfekt/auther-migrate:0.0.16-2326f7d"

// Spanner configuration
_spanner: {
	project:  "konfekt"
	instance: "konfekt-prod-db"
	database: "konfekt-prod"
}

// Common environment variables for database access
_dbEnv: [...corev1.#EnvVar] & [
	{name: "ENVIRONMENT", value: "prod"},
	{name: "POSTGRES_DATABASE", value: _spanner.database},
	{name: "POSTGRES_HOST", value: "localhost"},
	{name: "POSTGRES_PORT", value: "5432"},
	{name: "POSTGRES_USER", value: ""},
	{name: "POSTGRES_PASS", value: ""},
]

// =============================================================================
// Manifests
// =============================================================================

namespace: (k8s.#namespace & {name: _namespace}).manifest

serviceAccount: (k8s.#gkeServiceAccount & {
	name:              "deployment-sa"
	namespace:         _namespace
	gcpServiceAccount: "spanner-sa@konfekt.iam.gserviceaccount.com"
}).manifest

migrationJob: (k8s.#migrationJob & {
	name:               "db"
	namespace:          _namespace
	serviceAccountName: "deployment-sa"
	initContainers: [(k8s.#pgAdapterContainer & {
		project:  _spanner.project
		instance: _spanner.instance
		database: _spanner.database
	}).spec & {restartPolicy: "Always"}]
	containers: [{
		name:  "pgmigrate"
		image: _migrateImage
		env:   _dbEnv
	}]
}).manifest

rollout: (k8s.#rollout & {
	name:               _name
	namespace:          _namespace
	serviceAccountName: "deployment-sa"
	containers: [
		(k8s.#container & {
			name:  _name
			image: _image
			env: list.Concat([_dbEnv, [
				{name: "NOTIFY_SERVICE_URL", value: "http://localhost:5010"},
				{name: "WEBAUTHN_SERVICE_URL", value: "https://api.konfekt.dev/webauthn"},
				{name: "WEBAUTHN_RP_ID", value: "konfekt.dev"},
				{name: "WEBAUTHN_RP_NAME", value: "konfekt"},
				{name: "WEBAUTHN_ORIGIN", value: "https://konfekt.dev"},
			]])
		}).spec,
		(k8s.#pgAdapterContainer & {
			project:  _spanner.project
			instance: _spanner.instance
			database: _spanner.database
		}).spec,
	]
}).manifest

service: (k8s.#service & {
	name:      _name
	namespace: _namespace
}).manifest

// Export all manifests as a list
manifests: [namespace, serviceAccount, migrationJob, rollout, service]
