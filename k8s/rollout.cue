package k8s

import core "cue.dev/x/k8s.io/api/core/v1"

import "list"

rollout: #Env: *list.Concat([rollout.#CommonEnv, rollout.#ExtraEnv]) | _
rollout: #CommonEnv: *spanner.#CommonEnv | _
rollout: #ExtraEnv: [...core.#EnvVar] | *[]
rollout: #Port: int | *8080

rollout: #Rollout: {
	apiVersion: "argoproj.io/v1alpha1"
	kind:       "Rollout"
	metadata: {
		name:      #Name
		namespace: #Name
	}
	spec: replicas: 1
	spec: strategy: canary: steps: [{
		setWeight: 0
	}, {
		pause: duration: 1
	}, {
		setWeight: 50
	}, {
		pause: duration: 1
	}]
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
		initContainers: [spanner.#Sidecar]
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
			env: rollout.#Env
		}]
	}
}

rollout: #Service: core.#Service & {
	metadata: name:      #Name
	metadata: namespace: #Name
	spec: selector: app: #Name
	spec: ports: [
		{
			protocol: "TCP"
			port:     rollout.#Port
		},
	]
}
