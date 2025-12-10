// Example: Go service with Spanner database and migrations (like auther)
// This shows how to compose workflow components using list.Concat

package examples

import (
	"list"
	"github.com/emillamm/templates/templates/github"
)

// Configuration values - customize per project
_goprivate: "github.com/myorg/*"

// =============================================================================
// Test workflow
// =============================================================================
testWorkflow: github.#Workflow & {
	name: "Test"

	on: github.#PullRequestTrigger & {
		pull_request: "paths-ignore": github.#StandardPathsIgnore
	}

	jobs: test: github.#UbuntuRunner & {
		// Compose steps using list.Concat
		steps: list.Concat([
			[github.#CheckoutStep],
			github.#PrivateRepoAccess.steps,
			github.#DevboxSetup.steps,
			github.#GoCaching.steps,
			[(github.#devboxServicesStep & {
				init:    "init"
				migrate: "migrate"
				services: ["postgresql", "backend"]
			}).step],
			[(github.#devboxRunStepWithEnv & {
				name:    "Run backend tests"
				command: "test-backend"
				env: {
					GH_TOKEN:  github.#PrivateRepoAccess.env.GH_TOKEN
					GOPRIVATE: _goprivate
				}
			}).step],
		])
	}
}

// =============================================================================
// Publish workflow
// =============================================================================

// Define publishing config once
_publishConfig: github.#GARPublish & {
	_images: [
		{suffix: "-service", dockerfile: "service.Dockerfile"},
		{suffix: "-migrate", dockerfile: "migrate.Dockerfile"},
	]
	_secrets: "github_token=${{ steps.get-token.outputs.token }}"
}

publishWorkflow: github.#Workflow & {
	name: "Publish Docker"

	on: github.#PushTrigger & {
		push: "paths-ignore": github.#StandardPathsIgnore
	}

	jobs: publish: github.#UbuntuRunner & {
		name:        "Publish"
		permissions: _publishConfig.permissions

		steps: list.Concat([
			[github.#CheckoutStep],
			github.#PrivateRepoAccess.steps,
			github.#DevboxSetup.steps,
			github.#GoCaching.steps,
			[(github.#devboxServicesStep & {
				init:    "init"
				migrate: "migrate"
				services: ["postgresql", "backend"]
			}).step],
			[(github.#devboxRunStepWithEnv & {
				name:    "Run backend tests"
				command: "test-backend"
				env: {
					GH_TOKEN:  github.#PrivateRepoAccess.env.GH_TOKEN
					GOPRIVATE: _goprivate
				}
			}).step],
			_publishConfig.steps,
		])
	}
}
