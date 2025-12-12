package steps

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions"

gar: #ArtifactRegistryProvider:   string
gar: #ArtifactRegistrySA:         string
gar: #ArtifactRegistryRegion:     string
gar: #ArtifactRegistryRepository: string
gar: #GCPProject:                 string
gar: #Dockerfile:                 *"Dockerfile" | _
gar: #Dockerfiles: *["Dockerfile"] | _

gar: #AuthStep: githubactions.#Step & {
	id:   "auth"
	name: "Authenticate with Google Cloud"
	uses: ghactions.#GoogleAuthAction
	with: {
		token_format:               "access_token"
		workload_identity_provider: gar.#ArtifactRegistryProvider
		service_account:            gar.#ArtifactRegistrySA
		access_token_lifetime:      "300s"
	}
}

gar: #LoginStep: githubactions.#Step & {
	name: "Login to Artifact Registry"
	uses: ghactions.#DockerLoginAction
	with: {
		registry: "\(gar.#ArtifactRegistryRegion)-docker.pkg.dev"
		username: "oauth2accesstoken"
		password: "${{ steps.auth.outputs.access_token }}"
	}
}

gar: #PushStep: githubactions.#Step & {
	name: "Tag Docker image and push to Google Artifact Registry"
	uses: ghactions.#DockerPushAction
	with: {
		file: gar.#Dockerfile
		push: true
		secrets: """
			github_token=${{ steps.get-token.outputs.token }}
			"""
		tags: """
	\(gar.#ArtifactRegistryRegion)-docker.pkg.dev/\(gar.#GCPProject)/\(gar.#ArtifactRegistryRepository)/${{ github.event.repository.name }}-migrate:${{ steps.get-version.outputs.nextStrict }}-${{ steps.get-sha7.outputs.sha7 }}
	"""
	}

}

gar: #PushSteps: [
	//for i in ["a", "b"] if true githubactions.#Step & {
	for i in gar.#Dockerfiles {
		githubactions.#Step & {
			name: "Tag Docker image and push to Google Artifact Registry"
			uses: ghactions.#DockerPushAction
			with: {
				file: i
				push: true
				secrets: """
					github_token=${{ steps.get-token.outputs.token }}
					"""
				tags: """
		\(gar.#ArtifactRegistryRegion)-docker.pkg.dev/\(gar.#GCPProject)/\(gar.#ArtifactRegistryRepository)/${{ github.event.repository.name }}-migrate:${{ steps.get-version.outputs.nextStrict }}-${{ steps.get-sha7.outputs.sha7 }}
		"""
			}
		}
	},
]
