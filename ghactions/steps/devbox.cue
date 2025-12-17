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

devbox: #DevboxCueGenVerifyStep: devbox.#DevboxRunStep & {
	name: "Verify that cue-generated files are up to date"
	run: """
		before=$(git status --porcelain)
		devbox run cue-gen
		after=$(git status --porcelain)
		if [ "$before" != "$after" ]; then
		  echo "Error: 'devbox run cue-gen' produced new uncommitted changes:"
		  echo "Before:"
		  echo "$before"
		  echo "After:"
		  echo "$after"
		  exit 1
		fi
		"""
}

devbox: #DevboxCIStep: devbox.#DevboxRunStep & {
	name: "Run devbox CI task"
	run:  devbox.#DevboxRunCICommand
}

devbox: #DevboxReleaseStep: devbox.#DevboxRunStep & {
	name: "Run devbox release task"
	run:  "devbox run cue-gen"
}
