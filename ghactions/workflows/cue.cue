package workflows

cue: #PublishCuefig: #Workflow & {
	name: "Publish"
	on: push: {}
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
