package k8s

import core "cue.dev/x/k8s.io/api/core/v1"

import apps "cue.dev/x/k8s.io/api/apps/v1"

import "list"

// service account (shared with rollout, migration job, ...)
deployment: #GSA?: string
deployment: #ServiceAccount: core.#ServiceAccount & {
	metadata: {
		if deployment.#GSA != _|_ {
			annotations: "iam.gke.io/gcp-service-account": deployment.#GSA
		}
		name:      "deployment-sa"
		namespace: #Name
		annotations: "argocd.argoproj.io/sync-wave": "-1"
	}
}

// k8s deployment configuration
deployment: #Env: [...core.#EnvVar] | *#CommonEnv
deployment: #ExtraEnv: [...core.#EnvVar] | *[]
deployment: #Port: int | *8080
deployment: #InitContainers: [...core.#Container]

deploymentconfiguration: stateful: deployment & {
	#Env: list.Concat([#CommonEnv, spanner.#Env])
	#InitContainers: [spanner.#Sidecar]
}

deployment: #Deployment: apps.#Deployment & {
	metadata: {
		name:      #Name
		namespace: #Name
	}
	spec: replicas: 1
	spec: selector: matchLabels: app: #Name
	spec: template: metadata: labels: app: #Name
	spec: template: spec: {
		terminationGracePeriodSeconds: 25
		affinity: {
			// gke-spot for autopilot
			nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
				matchExpressions: [{
					key:      "cloud.google.com/gke-spot"
					operator: "In"
					values: ["true"]
				}]
			}]
		}
		serviceAccountName: "deployment-sa"
		initContainers:     deployment.#InitContainers
		containers: [{
			name:            #Name
			imagePullPolicy: "IfNotPresent"
			image:           "\(#Region)-docker.pkg.dev/\(#Project)/\(#Project)/\(#Name)-service:\(#ContainerVersion)"
			ports: [{
				name:          "http"
				containerPort: 8080
			}]
			readinessProbe: {
				httpGet: {
					path: "/health"
					port: 8080
				}
				initialDelaySeconds: 5
				timeoutSeconds:      3
			}
			livenessProbe: {
				httpGet: {
					path: "/health"
					port: 8080
				}
				initialDelaySeconds: 5
				timeoutSeconds:      3
				failureThreshold:    10
			}
			resources: requests: {
				cpu:                 "250m"
				memory:              "512Mi"
				"ephemeral-storage": "1Gi"
			}
			env: list.Concat([deployment.#Env, deployment.#ExtraEnv])
		}]
	}
}

deployment: #Service: core.#Service & {
	metadata: name:      #Name
	metadata: namespace: #Name
	spec: selector: app: #Name
	spec: ports: [
		{
			protocol: "TCP"
			port:     deployment.#Port
		},
	]
}
