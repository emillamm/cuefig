package steps

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions"

gar: #ArtifactRegistryProvider:   string
gar: #ArtifactRegistrySA:         string
gar: #ArtifactRegistryRegion:     string
gar: #ArtifactRegistryRepository: string
gar: #GCPProject:                 string
gar: #ContainerConfig:            #ContainerConfig | gar.containerconfig.#SimpleService

#ContainerConfig: {
	#Name: string
	#Containers: [#Container, ...]
}

#Container: {
	#Dockerfile: string
	#Image:      string
}

// Simple configuration with a container
gar: containerconfig: #SimpleService: T=#ContainerConfig & {
	#Name: string | *"${{ github.event.repository.name }}"
	#Containers: [
		#Container & {
			#Dockerfile: "Dockerfile"
			#Image:      "\(T.#Name)-service"
		},
	]
}

// Stateful configuration with service and database migration containers
gar: containerconfig: #StatefulService: T=#ContainerConfig & {
	#Name: string | *"${{ github.event.repository.name }}"
	#Containers: [
		#Container & {
			#Dockerfile: "service.Dockerfile"
			#Image:      "\(T.#Name)-service"
		},
		#Container & {
			#Dockerfile: "migrate.Dockerfile"
			#Image:      "\(T.#Name)-migrate"
		},
	]
}

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

gar: #PushSteps: [
	for i in gar.#ContainerConfig.#Containers {
		githubactions.#Step & {
			name: "Push image to Google Artifact Registry"
			uses: ghactions.#DockerPushAction
			with: {
				file: i.#Dockerfile
				push: true
				secrets: """
					github_token=${{ steps.get-token.outputs.token }}
					"""
				tags: """
		\(gar.#ArtifactRegistryRegion)-docker.pkg.dev/\(gar.#GCPProject)/\(gar.#ArtifactRegistryRepository)/\(i.#Image):${{ steps.get-version.outputs.nextStrict }}-${{ steps.get-sha7.outputs.sha7 }}
		"""
			}
		}
	},
]
