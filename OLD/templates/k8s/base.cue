// Base Kubernetes templates for composing deployments
package k8s

import (
	corev1 "k8s.io/api/core/v1"
	batchv1 "k8s.io/api/batch/v1"
	rolloutsv1alpha1 "github.com/argoproj/argo-rollouts/pkg/apis/rollouts/v1alpha1"
	"github.com/emillamm/templates/schemas/k8s"
)

// =============================================================================
// Namespace
// =============================================================================

#namespace: {
	name: string

	manifest: corev1.#Namespace & {
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			"name": name
			labels: "name": name
		}
	}
}

// =============================================================================
// Service Account
// =============================================================================

#serviceAccount: {
	name:      string
	namespace: string
	annotations: {[string]: string} | *{}

	manifest: corev1.#ServiceAccount & {
		apiVersion: "v1"
		kind:       "ServiceAccount"
		metadata: {
			"name":        name
			"namespace":   namespace
			"annotations": annotations
		}
	}
}

// GKE Workload Identity service account
#gkeServiceAccount: {
	name:              string
	namespace:         string
	gcpServiceAccount: string

	_base: #serviceAccount & {
		"name":      name
		"namespace": namespace
		annotations: {
			"iam.gke.io/gcp-service-account": gcpServiceAccount
			"argocd.argoproj.io/sync-wave":   "-1"
		}
	}

	manifest: _base.manifest
}

// =============================================================================
// Service
// =============================================================================

#service: {
	name:      string
	namespace: string
	port:      int | *8080
	selector: {[string]: string} | *{app: name}

	manifest: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			"name":      name
			"namespace": namespace
		}
		spec: {
			"selector": selector
			ports: [{
				protocol: "TCP"
				"port":   port
			}]
		}
	}
}

// =============================================================================
// Container helpers
// =============================================================================

#container: {
	name:  string
	image: string
	port:  int | *8080
	env: [...corev1.#EnvVar] | *[]
	resources: corev1.#ResourceRequirements | *{
		requests: {
			cpu:                 "250m"
			memory:              "512Mi"
			"ephemeral-storage": "1Gi"
		}
	}
	healthPath: string | *"/health"

	spec: corev1.#Container & {
		"name":          name
		"image":         image
		imagePullPolicy: "IfNotPresent"
		ports: [{
			"name":        "http"
			containerPort: port
		}]
		"env":       env
		"resources": resources
		readinessProbe: {
			httpGet: {
				path:   healthPath
				"port": port
			}
			initialDelaySeconds: 5
			timeoutSeconds:      3
		}
		livenessProbe: {
			httpGet: {
				path:   healthPath
				"port": port
			}
			initialDelaySeconds: 5
			timeoutSeconds:      3
			failureThreshold:    10
		}
	}
}

// PGAdapter sidecar container for Cloud Spanner
#pgAdapterContainer: {
	project:  string
	instance: string
	database: string
	port:     int | *5432

	spec: corev1.#Container & {
		name:  "pgadapter"
		image: "gcr.io/cloud-spanner-pg-adapter/pgadapter"
		ports: [{containerPort: port}]
		args: [
			"-p \(project)",
			"-i \(instance)",
			"-d \(database)",
			"-x",
		]
		resources: requests: {
			memory: "512Mi"
			cpu:    "250m"
		}
	}
}

// =============================================================================
// GKE Spot affinity
// =============================================================================

#gkeSpotAffinity: corev1.#Affinity & {
	nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
		matchExpressions: [{
			key:      "cloud.google.com/gke-spot"
			operator: "In"
			values: ["true"]
		}]
	}]
}

// =============================================================================
// Argo Rollout
// =============================================================================

#rollout: {
	name:               string
	namespace:          string
	replicas:           int | *1
	serviceAccountName: string | *""
	containers: [...corev1.#Container]
	affinity: corev1.#Affinity | *#gkeSpotAffinity

	manifest: rolloutsv1alpha1.#Rollout & {
		apiVersion: "argoproj.io/v1alpha1"
		kind:       "Rollout"
		metadata: {
			"name":      name
			"namespace": namespace
		}
		spec: {
			"replicas": replicas
			strategy: canary: steps: [
				{setWeight: 0},
				{pause: duration: 1},
				{setWeight: 50},
				{pause: duration: 1},
			]
			selector: matchLabels: app: name
			template: {
				metadata: labels: app: name
				spec: {
					terminationGracePeriodSeconds: 25
					if serviceAccountName != "" {
						"serviceAccountName": serviceAccountName
					}
					"affinity":   affinity
					"containers": containers
				}
			}
		}
	}
}

// =============================================================================
// Migration Job (ArgoCD Sync Hook)
// =============================================================================

#migrationJob: {
	name:               string
	namespace:          string
	serviceAccountName: string
	initContainers: [...corev1.#Container] | *[]
	containers: [...corev1.#Container]

	manifest: batchv1.#Job & {
		apiVersion: "batch/v1"
		kind:       "Job"
		metadata: {
			"name":      "\(name)-migrate"
			"namespace": namespace
			annotations: {
				"argocd.argoproj.io/hook":               "Sync"
				"argocd.argoproj.io/hook-delete-policy": "HookSucceeded"
				"argocd.argoproj.io/sync-wave":          "-1"
			}
		}
		spec: {
			ttlSecondsAfterFinished: 360
			template: spec: {
				"serviceAccountName": serviceAccountName
				if len(initContainers) > 0 {
					"initContainers": initContainers
				}
				"containers":  containers
				restartPolicy: "Never"
			}
			backoffLimit: 4
		}
	}
}

// =============================================================================
// ArgoCD Application
// =============================================================================

#argocdApp: {
	name:      string
	repoURL:   string
	path:      string | *"manifests"
	namespace: string | *"argocd"

	manifest: k8s.#Application & {
		metadata: {
			"name":      name
			"namespace": namespace
			finalizers: ["resources-finalizer.argocd.argoproj.io"]
		}
		spec: {
			project: "default"
			source: {
				"repoURL":      repoURL
				targetRevision: "HEAD"
				"path":         path
			}
			destination: "name": "in-cluster"
			syncPolicy: automated: {
				selfHeal: true
				prune:    true
			}
		}
	}
}
