package steps

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions"

cue: #InstallStep: githubactions.#Step & {
	name: "Install CUE"
	uses: ghactions.#CueInstallAction
}

cue: #LoginStep: githubactions.#Step & {
	name: "Login to Artifact Registry"
	uses: ghactions.#DockerLoginAction
	with: {
		registry: "ghcr.io"
		username: "${{ github.actor }}"
		password: "${{ secrets.GITHUB_TOKEN }}"
	}
}

cue: #PublishStep: githubactions.#Step & {
	// E.g. "github.com/emillamm/cuefig=ghcr.io/emillamm,registry.cue.works
	env: CUE_REGISTRY: "github.com/${{ github.repository }}=ghcr.io/${{ github.repository_owner }},registry.cue.works"
	run: """
		cue mod publish "v${{ steps.get-version.outputs.nextStrict }}
		"""
}
