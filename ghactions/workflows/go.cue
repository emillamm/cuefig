package workflows

import "list"

go: #Test: #TestWorkflow & {
	jobs: test: steps: [
		#steps.github.#CheckoutStep,
		#steps.github.#RetrieveAccessTokenStep,
		#steps.github.#ConfigureAccessTokenStep,
		#steps.devbox.#DevboxInstallStep,
		#steps.devbox.#DevboxRunStep,
	]
}

go: #PublishService: #PublishWorkflow & {
	jobs: publish: permissions: {
		contents:   "write"
		"id-token": "write"
	}
	_steps: [
		#steps.github.#CheckoutStep,
		#steps.github.#RetrieveAccessTokenStep,
		#steps.github.#ConfigureAccessTokenStep,
		#steps.devbox.#DevboxInstallStep,
		#steps.go.#ModCacheStep,
		#steps.go.#BuildCacheStep,
		#steps.devbox.#DevboxRunStep,
		#steps.gar.#AuthStep,
		#steps.gar.#LoginStep,
		#steps.version.#GetVersionStep,
		#steps.version.#GetSha7Step,
		#steps.gar.#PushSteps, // Produces a list of steps
		#steps.version.#CreateTagStep,
	]
	jobs: publish: steps: list.FlattenN(_steps, 1)
}
