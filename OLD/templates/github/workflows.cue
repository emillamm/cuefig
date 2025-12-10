package github

import (
	"strings"
	"github.com/emillamm/templates/schemas/github"
)

// =============================================================================
// Core workflow building blocks
// =============================================================================

// Base workflow - just provides structure
#Workflow: github.#Workflow

// =============================================================================
// Trigger configurations
// =============================================================================

#PullRequestTrigger: github.#On & {
	pull_request: {
		branches: [...string] | *["main"]
		types: [...string] | *["opened", "reopened", "synchronize"]
	}
}

#PushTrigger: github.#On & {
	push: {
		branches: [...string] | *["main"]
	}
}

#StandardPathsIgnore: ["**/*.md", "manifests/**"]

// =============================================================================
// Job runners (open for composition)
// =============================================================================

#UbuntuRunner: {
	"runs-on": "ubuntu-latest"
	...
}

#MacOSRunner: {
	"runs-on": "macos-latest"
	...
}

// =============================================================================
// Service definitions (open for composition)
// =============================================================================

#PostgresService: {
	_image:    string | *"postgres"
	_password: string | *"postgres"
	_port:     string | *"5432"
	_memory:   string | *"3g"

	services: postgres: github.#Service & {
		image: _image
		env: POSTGRES_PASSWORD: _password
		ports: ["\(_port):5432"]
		options: "--health-cmd pg_isready --health-timeout 5s --health-retries 8 --memory=\(_memory)"
	}
	...
}

// =============================================================================
// Private repository access
// =============================================================================

#PrivateRepoAccess: {
	// Steps to add for private repo access
	steps: [
		#PrivateRepoTokenStep,
		#GitCredentialsStep,
	]

	// Environment variables to use in subsequent steps
	env: {
		GH_TOKEN: "${{ steps.get-token.outputs.token }}"
	}
}

// =============================================================================
// Devbox setup
// =============================================================================

#DevboxSetup: {
	steps: [#DevboxStep]
}

// Create a devbox services step
#devboxServicesStep: {
	name:    string | *"Start required services"
	init:    string | *""
	migrate: string | *""
	services: [...string] | *[]

	step: {
		"name": name
		run: strings.Join([
			if init != "" {"devbox run \(init)"},
			if migrate != "" {"devbox run \(migrate)"},
			for s in services {"devbox services start \(s)"},
		], "\n")
	}
}

// Create a devbox run step
#devboxRunStep: {
	name:    string
	command: string
	step: {
		"name": name
		run:    "devbox run \(command)"
	}
}

// Create a devbox run step with environment
#devboxRunStepWithEnv: {
	name:    string
	command: string
	env: {[string]: string}
	step: {
		"name": name
		"env":  env
		run:    "devbox run \(command)"
	}
}

// =============================================================================
// Docker publishing
// =============================================================================

#GARPublish: {
	_images: [...{suffix: string, dockerfile: string}] | *[{suffix: "", dockerfile: "Dockerfile"}]
	_secrets: string | *""

	permissions: github.#Permissions & {
		contents:   "write"
		"id-token": "write"
	}

	steps: [
		#GCPAuthStep,
		#ArtifactRegistryLoginStep,
		#SemverStep,
		#Sha7Step,
		for img in _images {
			#DockerPushGARStep & {
				_dockerfile:  img.dockerfile
				_imageSuffix: img.suffix
				if _secrets != "" {
					_secrets: _secrets
				}
			}
		},
		#CreateTagStep,
	]
}

#GHCRPublish: {
	permissions: github.#Permissions & {
		contents:   "write"
		packages:   "write"
		"id-token": "write"
	}

	steps: [
		#SemverStep,
		#GHCRLoginStep,
		#DockerPushGHCRStep,
		#CreateTagStep & {
			_versionRef: "${{ steps.get-version.outputs.next }}"
		},
	]
}

// =============================================================================
// Language-specific caching (compose these in)
// =============================================================================

#GoCaching: {
	_hashPattern: string | *"**/*.go"

	steps: [
		#GoModCacheStep,
		#GoBuildCacheStep & {_hashPattern: _hashPattern},
	]
}
