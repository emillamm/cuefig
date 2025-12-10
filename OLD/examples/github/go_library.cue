// Example: Go library with postgres tests (like pgmigrate)
// Uses standard Go setup (not devbox) with postgres service, publishes to GHCR

package examples

import (
	"list"
	"github.com/emillamm/templates/templates/github"
)

// Go version configuration
_goSetup: github.#GoSetup & {_version: "1.24.x"}

// =============================================================================
// Test workflow
// =============================================================================
pgmigrateTestWorkflow: github.#Workflow & {
	name: "Test"

	on: github.#PullRequestTrigger & {
		pull_request: "paths-ignore": ["**/*.md"]
	}

	jobs: test: github.#UbuntuRunner &
		github.#PostgresService &
		_goSetup.goMatrix & {

			steps: list.Concat([
				[github.#CheckoutStep],
				_goSetup.steps,
				github.#GoTest.steps,
			])
		}
}

// =============================================================================
// Publish workflow
// =============================================================================
pgmigratePublishWorkflow: github.#Workflow & {
	name: "Publish"

	on: github.#PushTrigger & {
		push: "paths-ignore": ["**/*.md"]
	}

	jobs: publish: github.#UbuntuRunner &
		github.#PostgresService &
		_goSetup.goMatrix & {

			permissions: github.#GHCRPublish.permissions

			steps: list.Concat([
				[github.#CheckoutStep],
				[github.#SemverStep],
				_goSetup.steps,
				github.#GoTest.steps,
				github.#GHCRPublish.steps,
			])
		}
}
