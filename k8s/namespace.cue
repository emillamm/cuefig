package k8s

import core "cue.dev/x/k8s.io/api/core/v1"

#Name: string

#Namespace: core.#Namespace & {
	metadata: {
		name: #Name
		labels: name: #Name
	}
}
