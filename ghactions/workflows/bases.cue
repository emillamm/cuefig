package workflows

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions/steps"

import "list"

#steps: steps

#Workflow: githubactions.#Workflow & {
	#Runner: *"ubuntu-latest" | _
	#Branches: ["main"]
	#PathsIgnore: ["**/*.md", "manifests/**", ".release"]
	on: [_]: {
		branches:       #Branches
		"paths-ignore": #PathsIgnore
	}
	jobs: [_]: "runs-on": #Runner
}

#BuildWorkflow: #Workflow & {

	// Required: Build step
	#BuildStep: githubactions.#Step

	#AppTokenConfig: {
		#GHAppTokenSteps: [...githubactions.#Step] | *[]
		#GHTokenMixin: githubactions.#Step | *_
	}

	#CacheConfig: {
		#BuildCacheSteps: [...githubactions.#Step] | *[]
	}

	#DevboxConfig: {
		#DevboxInstallSteps: [...githubactions.#Step] | *[]
		#CueGenVerifySteps: [...githubactions.#Step] | *[]
	}

	#ReleaseConfig: {
		#GenerateVersionSteps: [...githubactions.#Step] | *[]
		#PushVersionTagSteps: [...githubactions.#Step] | *[]
		#ContentModifyConfig: {
			#ContentModifySteps: [...githubactions.#Step] | *[]
			#ContentPushSteps: [...githubactions.#Step] | *[]
		}
		#GithubReleaseSteps: [...githubactions.#Step] | *[]

		// Allow nested lists of steps, which get flattened by list.FlattenN
		#PushContainersSteps: [...(githubactions.#Step | [...githubactions.#Step])] | *[]
	}

	_steps: [
		// Prepare repo
		#steps.github.#CheckoutStep,

		// GH app token for access to private repos
		#AppTokenConfig.#GHAppTokenSteps,

		// Prepare devbox
		#DevboxConfig.#DevboxInstallSteps,

		// Cache build output
		#CacheConfig.#BuildCacheSteps,

		// Verify empty cue-gen output
		#DevboxConfig.#CueGenVerifySteps,

		// Prepare release
		#ReleaseConfig.#GenerateVersionSteps,
		#ReleaseConfig.#ContentModifyConfig.#ContentModifySteps,

		// Build step
		#BuildStep & #AppTokenConfig.#GHTokenMixin,

		// Push containers
		#ReleaseConfig.#PushContainersSteps,

		// Push version tag
		#ReleaseConfig.#PushVersionTagSteps,

		// Generate release
		#ReleaseConfig.#GithubReleaseSteps,

		// Push commit with repo content changes
		#ReleaseConfig.#ContentModifyConfig.#ContentPushSteps,
	]
	jobs: [_]: steps: list.FlattenN(_steps, 2)
}

#TestWorkflow: #BuildWorkflow & {
	name: "Test"
	on: pull_request: types: ["opened", "reopened", "synchronize"]
	jobs: test: permissions: {
		contents: "read"
		packages: "read"
	}
}

#PublishWorkflow: #BuildWorkflow & {
	name: "Publish"
	on: push: {}
	jobs: publish: permissions: {
		contents:   "write"
		"id-token": "write"
		packages:   "read"
	}
}

// Mixins

mixins: #WithAppToken: #BuildWorkflow & {
	#AppTokenConfig: {
		#GHAppTokenSteps: [
			#steps.github.#RetrieveAccessTokenStep,
			#steps.github.#ConfigureAccessTokenStep,
		]
		#GHTokenMixin: #steps.github.#GHAuthMixin
	}
}

// Generate and push semver version of type "v1.2.3-abcdefg"
mixins: release: #WithSemver: #PublishWorkflow & {
	#ReleaseConfig: {
		#GenerateVersionSteps: [
			#steps.version.#GetVersionStep,
			#steps.version.#GetSha7Step,
		]
		#PushVersionTagSteps: [
			#steps.version.#CreateTagStep,
		]
	}
}

mixins: release: #WithCueGenModify: release.#WithSemver & {

	#AppTokenConfig: #GHTokenMixin: githubactions.#Step | *_

	#ReleaseConfig: {
		#ContentModifyConfig: {
			#ContentModifySteps: [
				#steps.version.#WriteReleaseFileStep,
				#steps.devbox.#DevboxReleaseStep & #AppTokenConfig.#GHTokenMixin,
				#steps.version.#ReleaseCommitStep,
			]
			#ContentPushSteps: [
				#steps.version.#ReleasePushStep,
			]
		}
	}
}

mixins: release: #WithPushContainers: release.#WithSemver & {
	#ReleaseConfig: {
		#PushContainersSteps: [
			#steps.gar.#AuthStep,
			#steps.gar.#LoginStep,
			#steps.gar.#PushImageSteps, // Produces a list of steps that will be flattened
		]
	}
}

mixins: release: #WithGithubRelease: release.#WithSemver & {
	#ReleaseArtifacts: string
	#ReleaseConfig: {
		#GithubReleaseSteps: [
			#steps.version.#CreateReleaseStep & {
				#Version:   "${{ steps.get-version.outputs.nextStrict }}-${{ steps.get-sha7.outputs.sha7 }}"
				#Artifacts: #ReleaseArtifacts
			},
		]
	}
}

mixins: #WithDevbox: #BuildWorkflow & {

	#BuildStep: #steps.devbox.#DevboxCIStep

	#AppTokenConfig: #GHTokenMixin: githubactions.#Step | *_

	#DevboxConfig: {
		#DevboxInstallSteps: [
			#steps.devbox.#DevboxInstallStep,
		]
		#CueGenVerifySteps: [
			#steps.cue.#LoginStep,
			#steps.devbox.#DevboxCueGenVerifyStep & #AppTokenConfig.#GHTokenMixin,
		]
	}

}
