package workflows

import "list"

go: #TestPublic: #TestWorkflow & {
	jobs: test: permissions: {
		contents: "read"
		packages: "read"
	}
	jobs: test: steps: [
		// Prepare repo
		#steps.github.#CheckoutStep,
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

go: #TestPrivate: #TestWorkflow & {
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
		#steps.devbox.#DevboxCueGenVerifyStep & #steps.github.#GHAuthMixin,
		// Run tests
		#steps.devbox.#DevboxCIStep & #steps.github.#GHAuthMixin,
	]
}

go: #PublishServicePrivate: #PublishWorkflow & {
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
		#steps.devbox.#DevboxCueGenVerifyStep & #steps.github.#GHAuthMixin,
		// Prepare release
		#steps.version.#GetVersionStep,
		#steps.version.#GetSha7Step,
		#steps.version.#WriteReleaseFileStep,
		#steps.devbox.#DevboxReleaseStep & #steps.github.#GHAuthMixin,
		#steps.version.#ReleaseCommitStep,
		// Run tests
		#steps.devbox.#DevboxCIStep & #steps.github.#GHAuthMixin,
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

go: #PublishLibraryPublic: #PublishWorkflow & {
	jobs: publish: permissions: {
		contents: "write"
		packages: "read"
	}
	jobs: publish: steps: [
		// Prepare repo
		#steps.github.#CheckoutStep,
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
		// Run tests
		#steps.devbox.#DevboxCIStep,
		// Push version
		#steps.version.#CreateTagStep,
	]
}

go: #PublishLibraryPrivate: #PublishWorkflow & {
	jobs: publish: permissions: {
		contents: "write"
		packages: "read"
	}
	jobs: publish: steps: [
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
		#steps.devbox.#DevboxCueGenVerifyStep & #steps.github.#GHAuthMixin,
		// Prepare release
		#steps.version.#GetVersionStep,
		#steps.version.#GetSha7Step,
		// Run tests
		#steps.devbox.#DevboxCIStep & #steps.github.#GHAuthMixin,
		// Push version
		#steps.version.#CreateTagStep,
	]
}
