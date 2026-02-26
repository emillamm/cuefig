package steps

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions"

import "strings"

import "list"

cue: #Registries: [string] | *[]
cue: _predefined_registries: ["github.com/${{ github.repository }}=ghcr.io/${{ github.repository_owner }}", "registry.cue.works"]

cue: #InstallStep: githubactions.#Step & {
	name: "Install CUE"
	uses: ghactions.#CueInstallAction
}

cue: #LoginStep: githubactions.#Step & {
	name: "Generate CUE OCI login creds"
	run: """
		mkdir -p ~/.docker
		echo '{"auths":{"ghcr.io":{"auth":"'$(echo -n "${{ github.actor }}:${{ secrets.GITHUB_TOKEN }}" | base64)'"}}}' > ~/.docker/config.json
		"""
}

cue: #PublishStep: githubactions.#Step & {
	// E.g. "github.com/emillamm/cuefig=ghcr.io/emillamm,registry.cue.works
	env: CUE_REGISTRY: strings.Join(list.Concat([cue._predefined_registries, cue.#Registries]), ",")
	run: """
		cue mod publish "v${{ steps.get-version.outputs.nextStrict }}"
		"""
}
