// Example: Simple Go service without database (like router)
// Uses devbox but no migrations or database services

package examples

import (
	"list"
	"github.com/emillamm/templates/templates/github"
)

// =============================================================================
// Test workflow
// =============================================================================
routerTestWorkflow: github.#Workflow & {
	name: "Test"

	on: github.#PullRequestTrigger

	jobs: test: github.#UbuntuRunner & {
		steps: list.Concat([
			[github.#CheckoutStep],
			github.#DevboxSetup.steps,
			github.#GoCaching.steps,
			[(github.#devboxServicesStep & {
				services: ["backend"]
			}).step],
			[(github.#devboxRunStep & {
				name:    "Run backend tests"
				command: "test-backend"
			}).step],
		])
	}
}

// =============================================================================
// Publish workflow
// =============================================================================
routerPublishWorkflow: github.#Workflow & {
	name: "Publish Docker"

	on: github.#PushTrigger & {
		push: "paths-ignore": github.#StandardPathsIgnore
	}

	jobs: publish: github.#UbuntuRunner & {
		name:        "Publish"
		permissions: github.#GARPublish.permissions

		steps: list.Concat([
			[github.#CheckoutStep],
			github.#GARPublish.steps,
		])
	}
}
