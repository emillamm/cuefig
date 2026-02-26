package example

import "github.com/emillamm/cuefig/ghactions/workflows"

_wf: workflows & {}

exampleReleasePrivate: _wf.#PublishWorkflow &
	workflows.mixins.#WithAppToken &
	workflows.mixins.#WithDevbox &
	workflows.mixins.release.#WithGithubRelease & {
		#ReleaseArtifacts: "path-to-release-artifacts"
	}
