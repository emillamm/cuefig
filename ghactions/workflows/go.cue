package workflows

import "list"

go: #Test: #TestWorkflow & {
	jobs: test: permissions: {
		contents: "read"
		packages: "read"
	}
	jobs: test: steps: [
		// Prepare repo
		#steps.github.#CheckoutStep,
		#steps.github.#RetrieveAccessTokenStep,
		#steps.github.#ConfigureAccessTokenStep,
		// Prepare devbox
		#steps.devbox.#DevboxInstallStep,
		#steps.go.#ModCacheStep,
		#steps.go.#BuildCacheStep,
		// Verify empty cue-gen output
		#steps.cue.#LoginStep,
		#steps.devbox.#DevboxCueGenVerifyStep,
		// Run tests
		#steps.devbox.#DevboxCIStep,
	]
}

go: #PublishService: #PublishWorkflow & {
	jobs: publish: permissions: {
		contents:   "write"
		"id-token": "write"
		packages:   "read"
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
		// Verify empty cue-gen output
		#steps.cue.#LoginStep,
		#steps.devbox.#DevboxCueGenVerifyStep,
		// Prepare release
		#steps.version.#GetVersionStep,
		#steps.version.#GetSha7Step,
		#steps.version.#WriteReleaseFileStep,
		#steps.devbox.#DevboxReleaseStep,
		#steps.version.#ReleaseCommitStep,
		// Run tests
		#steps.devbox.#DevboxCIStep,
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
