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

exampleTestPublic:            _wf.go.#TestPublic
exampleTestPrivate:           _wf.go.#TestPrivate
examplePublishService:        _wf.go.#PublishServicePrivate
examplePublishLibraryPublic:  _wf.go.#PublishLibraryPublic
examplePublishLibraryPrivate: _wf.go.#PublishLibraryPrivate
examplePublishCuefig:         workflows.cue.#PublishCuefig
