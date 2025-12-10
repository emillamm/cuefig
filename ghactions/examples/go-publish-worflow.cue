package example

import "github.com/emillamm/cuefig/ghactions/workflows"

_wf: workflows & {
	#steps: gar: #ArtifactRegistryProvider:   "xyz"
	#steps: gar: #ArtifactRegistrySA:         "xyz"
	#steps: gar: #ArtifactRegistryRegion:     "xyz"
	#steps: gar: #ArtifactRegistryRepository: "xyz"
	#steps: gar: #GCPProject:                 "xyz"
	#steps: gar: #Dockerfiles: ["Dockerfile1", "Dockerfile2"]
}

example: _wf.go.#PublishService
