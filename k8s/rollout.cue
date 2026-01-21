package k8s

import core "cue.dev/x/k8s.io/api/core/v1"

import "list"

// rollout configuration
rollout: #RolloutName: string | *#Name
rollout: #Env: [...core.#EnvVar] | *#CommonEnv
rollout: #ExtraEnv: [...core.#EnvVar] | *[]
rollout: #Port: int | *8080
rollout: #InitContainers: [...core.#Container]

rolloutconfiguration: stateful: rollout & {
	#Env: list.Concat([#CommonEnv, spanner.#Env])
	#InitContainers: [spanner.#Sidecar]
}

rollout: #Rollout: {
	apiVersion: "argoproj.io/v1alpha1"
	kind:       "Rollout"
	metadata: {
		name:      rollout.#RolloutName
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
	spec: selector: matchLabels: app: rollout.#RolloutName
	spec: template: metadata: labels: app: rollout.#RolloutName
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
		initContainers:     rollout.#InitContainers
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
			env: list.Concat([rollout.#Env, rollout.#ExtraEnv])
		}]
	}
}

rollout: #Service: core.#Service & {
	metadata: name:      rollout.#RolloutName
	metadata: namespace: #Name
	spec: selector: app: rollout.#RolloutName
	spec: ports: [
		{
			protocol: "TCP"
			port:     rollout.#Port
		},
	]
}
