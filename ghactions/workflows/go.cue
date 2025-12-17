package workflows

import "list"

go: #Test: #TestWorkflow & {
	jobs: test: steps: [
		#steps.github.#CheckoutStep,
		#steps.github.#RetrieveAccessTokenStep,
		#steps.github.#ConfigureAccessTokenStep,
		#steps.devbox.#DevboxInstallStep,
		#steps.devbox.#DevboxRunCIStep,
	]
}

go: #PublishService: #PublishWorkflow & {
	jobs: publish: permissions: {
		contents:   "write"
		"id-token": "write"
	}
	_steps: [
		// Prepare repo
		#steps.github.#CheckoutStep,
		#steps.github.#RetrieveAccessTokenStep,
		#steps.github.#ConfigureAccessTokenStep,
		// Prepare devbox
		#steps.devbox.#DevboxInstallStep,
		#steps.go.#ModCacheStep,
		#steps.go.#BuildCacheStep,
		// Prepare release
		#steps.version.#GetVersionStep,
		#steps.version.#GetSha7Step,
		#steps.version.#WriteReleaseFileStep,
		#steps.cue.#LoginStep,
		#steps.devbox.#DevboxRunReleaseStep,
		#steps.version.#ReleaseCommitStep,
		// Run tests
		#steps.devbox.#DevboxRunCIStep,
		// Push containers
		#steps.gar.#AuthStep,
		#steps.gar.#LoginStep,
		#steps.gar.#PushImageSteps, // Produces a list of steps that will be flattened
		// Push version
		#steps.version.#CreateTagStep,
		#steps.version.#ReleasePushStep,
	]
	jobs: publish: steps: list.FlattenN(_steps, 1)
}
