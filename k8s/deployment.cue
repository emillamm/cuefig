package k8s

import core "cue.dev/x/k8s.io/api/core/v1"

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
