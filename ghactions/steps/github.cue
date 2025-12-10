package steps

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions"

github: #CheckoutStep: githubactions.#Step & {
	id:   "checkout"
	uses: ghactions.#CheckoutAction
}

github: #RetrieveAccessTokenStep: githubactions.#Step & {
	name: "Get github app access token"
	id:   "get-token"
	uses: ghactions.#GithubAppTokenAction
	with: {
		app_id:      "${{ secrets.REPO_READ_APP_ID }}"
		private_key: "${{ secrets.REPO_READ_TOKEN }}"
	}
	env: OPENSSL_CONF: "/dev/null"
}

github: #ConfigureAccessTokenStep: githubactions.#Step & {
	name: "Configure github app access token"
	run: """
		git config --global url."https://x-access-token:${{ steps.get-token.outputs.token }}@github.com/".insteadOf "https://github.com/"
		"""
}
