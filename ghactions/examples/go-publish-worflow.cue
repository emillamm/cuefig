package example

import "github.com/emillamm/cuefig/ghactions/workflows"

_wf: workflows & {
	#steps: gar: #ArtifactRegistryProvider:   "xyz"
	#steps: gar: #ArtifactRegistrySA:         "xyz"
	#steps: gar: #ArtifactRegistryRegion:     "xyz"
	#steps: gar: #ArtifactRegistryRepository: "xyz"
	#steps: gar: #GCPProject:                 "xyz"
	#steps: gar: #ContainerConfig:            gar.containerconfig.#SimpleService
}

example: _wf.go.#PublishService
//example: workflows.cue.#PublishCuefig
