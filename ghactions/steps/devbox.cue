package steps

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions"

devbox: #DevboxRunCICommand: *"devbox run ci" | _

devbox: #DevboxInstallStep: githubactions.#Step & {
	name: "Install Devbox and environment"
	uses: ghactions.#DevboxInstallAction
	with: "enable-cache": "true"
}

devbox: #DevboxRunStep: githubactions.#Step & {
	name: *"Run devbox command" | _
	env: {
		// Override existing GH_TOKEN to access
		// internal private repos.
		GH_TOKEN: "${{ steps.get-token.outputs.token }}"
	}
}

devbox: #DevboxRunCIStep: devbox.#DevboxRunStep & {
	name: "Run devbox CI task"
	run:  devbox.#DevboxRunCICommand
}

devbox: #DevboxRunReleaseStep: devbox.#DevboxRunStep & {
	name: "Run devbox release task"
	run:  "devbox run cue-gen"
}
