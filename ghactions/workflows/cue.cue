package workflows

cue: #PublishCuefig: #PublishWorkflow & {
	jobs: publish: permissions: {
		contents: "write"
		packages: "write"
	}
	jobs: publish: steps: [
		#steps.github.#CheckoutStep,
		#steps.cue.#InstallStep,
		#steps.version.#GetVersionStep,
		#steps.cue.#LoginStep,
		#steps.cue.#PublishStep,
		#steps.version.#CreateTagStep,
	]
}
