package github

import ( "github.com/emillamm/templates/schemas/github"

	// Common step definitions for reuse across workflows
)

#CheckoutStep: github.#Step & {
	name: "Checkout"
	uses: "actions/checkout@v5"
}

// Devbox installation step
#DevboxStep: github.#Step & {
	name: "Install Devbox and environment"
	uses: "emillamm/devbox-install-action@restore-cache-key-v0.13.0"
	with: {
		"enable-cache": "true"
	}
}

// Go setup step (for non-devbox projects)
#GoSetupStep: github.#Step & {
	_goVersion: string | *"1.24.x"
	name:       "Setup Go"
	uses:       "actions/setup-go@v5"
	with: {
		"go-version": _goVersion
	}
}

// Go modules cache step
#GoModCacheStep: github.#Step & {
	name: "Cache Go modules"
	uses: "actions/cache@v4"
	with: {
		path: "/home/runner/go/pkg/mod"
		key:  "go-cache-${{ runner.os }}-${{ hashFiles('go.sum') }}"
		"restore-keys": """
			go-mod-cache-${{ runner.os }}-
			go-mod-cache-
			"""
	}
}

// Go build cache step
#GoBuildCacheStep: github.#Step & {
	_hashPattern: string | *"**/*.go"
	name:         "Cache Go internal cache (to speed up tests)"
	uses:         "actions/cache@v4"
	with: {
		path: "/home/runner/.cache/go-build"
		key:  "go-cache-${{ runner.os }}-${{ hashFiles('\(_hashPattern)', 'go.sum') }}"
		"restore-keys": """
			go-cache-${{ runner.os }}-
			go-cache-
			"""
	}
}

// Private repository access token via GitHub App
#PrivateRepoTokenStep: github.#Step & {
	name: "Generate private repo access token"
	id:   "get-token"
	uses: "getsentry/action-github-app-token@v3"
	with: {
		app_id:      "${{ secrets.REPO_READ_APP_ID }}"
		private_key: "${{ secrets.REPO_READ_TOKEN }}"
	}
	env: {
		OPENSSL_CONF: "/dev/null"
	}
}

// Git credentials for private Go modules
#GitCredentialsStep: github.#Step & {
	_goprivate: string | *"github.com/*"
	name:       "Setup Git credentials for private go modules"
	run: """
		git config --global url."https://x-access-token:${{ steps.get-token.outputs.token }}@github.com/".insteadOf "https://github.com/"
		"""
}

// Google Cloud authentication
#GCPAuthStep: github.#Step & {
	id:   "auth"
	name: "Authenticate with Google Cloud"
	uses: "google-github-actions/auth@v3"
	with: {
		token_format:               "access_token"
		workload_identity_provider: "${{ vars.ARTIFACT_REGISTRY_PROVIDER }}"
		service_account:            "${{ vars.ARTIFACT_REGISTRY_SA }}"
		access_token_lifetime:      "300s"
	}
}

// Google Artifact Registry login
#ArtifactRegistryLoginStep: github.#Step & {
	name: "Login to Artifact Registry"
	uses: "docker/login-action@v3"
	with: {
		registry: "${{ vars.ARTIFACT_REGISTRY_REGION }}-docker.pkg.dev"
		username: "oauth2accesstoken"
		password: "${{ steps.auth.outputs.access_token }}"
	}
}

// GitHub Container Registry login
#GHCRLoginStep: github.#Step & {
	name: "Log in to the container registry"
	uses: "docker/login-action@v3"
	with: {
		registry: "ghcr.io"
		username: "${{ github.actor }}"
		password: "${{ secrets.GITHUB_TOKEN }}"
	}
}

// Semantic version computation
#SemverStep: github.#Step & {
	id:   "get-version"
	name: "Compute next version based on previous tag in commit history"
	uses: "ietf-tools/semver-action@v1"
	with: {
		token:                 "${{ github.token }}"
		branch:                "main"
		noVersionBumpBehavior: "patch"
	}
}

// Short SHA computation
#Sha7Step: github.#Step & {
	id:   "get-sha7"
	name: "Compute sha7 which will be used for tagging the image as \"x.y.z-sha7\""
	run:  "echo \"sha7=$(git rev-parse --short HEAD)\" >> $GITHUB_OUTPUT"
}

// Docker build and push to Google Artifact Registry
#DockerPushGARStep: github.#Step & {
	_dockerfile:  string | *"Dockerfile"
	_imageSuffix: string | *""
	_secrets:     string | *""
	id:           "docker-push-tagged\(_imageSuffix)"
	name:         "Tag Docker image and push to Google Artifact Registry"
	uses:         "docker/build-push-action@v6"
	with: {
		if _dockerfile != "Dockerfile" {
			file: _dockerfile
		}
		push: "true"
		if _secrets != "" {
			secrets: _secrets
		}
		let suffix = _imageSuffix
		tags: "${{ vars.ARTIFACT_REGISTRY_REGION }}-docker.pkg.dev/${{ vars.GCP_PROJECT }}/${{ vars.ARTIFACT_REGISTRY_REPOSITORY }}/${{ github.event.repository.name }}\(suffix):${{ steps.get-version.outputs.nextStrict }}-${{ steps.get-sha7.outputs.sha7 }}"
	}
}

// Docker build and push to GHCR
#DockerPushGHCRStep: github.#Step & {
	id:   "docker-push-tagged"
	name: "Tag docker image and push to container registry"
	uses: "docker/build-push-action@v5"
	with: {
		context: "."
		push:    "true"
		tags:    "ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}:${{ steps.get-version.outputs.nextStrict }},ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}:latest"
	}
}

// Create Git tag
#CreateTagStep: github.#Step & {
	_versionRef: string | *"${{ steps.get-version.outputs.nextStrict }}"
	name:        "Create tag"
	uses:        "actions/github-script@v8"
	with: {
		script: """
			github.rest.git.createRef({
			  owner: context.repo.owner,
			  repo: context.repo.repo,
			  ref: "refs/tags/\(_versionRef)",
			  sha: context.sha
			})
			"""
	}
}
