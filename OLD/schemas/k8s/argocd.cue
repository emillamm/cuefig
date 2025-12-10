// ArgoCD Application CRD schema (simplified)
// Full schema at: https://argo-cd.readthedocs.io/en/stable/operator-manual/application.yaml
package k8s

import "k8s.io/apimachinery/pkg/apis/meta/v1"

#Application: {
	apiVersion: "argoproj.io/v1alpha1"
	kind:       "Application"
	metadata:   v1.#ObjectMeta
	spec:       #ApplicationSpec
}

#ApplicationSpec: {
	project:     string | *"default"
	source:      #ApplicationSource
	destination: #ApplicationDestination
	syncPolicy?: #SyncPolicy
}

#ApplicationSource: {
	repoURL:        string
	targetRevision: string | *"HEAD"
	path:           string
	helm?: {
		valueFiles?: [...string]
		values?: string
	}
	kustomize?: {
		images?: [...string]
	}
}

#ApplicationDestination: {
	server?:    string
	name?:      string
	namespace?: string
}

#SyncPolicy: {
	automated?: {
		selfHeal?: bool
		prune?:    bool
	}
	syncOptions?: [...string]
}
