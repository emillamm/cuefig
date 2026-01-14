package steps

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions"

version: #GetVersionStep: githubactions.#Step & {
	id:   "get-version"
	name: "Compute next version based on previous tag in commit history"
	uses: ghactions.#SemverAction
	with: {
		token:                 "${{ github.token }}"
		branch:                "main"
		noVersionBumpBehavior: "patch"
	}
}

version: #GetSha7Step: githubactions.#Step & {
	id:   "get-sha7"
	name: "Compute sha7 which will be used for tagging the image as \"x.y.z-sha7\""
	run: """
		echo "sha7=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT
		"""
}

version: #WriteReleaseFileStep: githubactions.#Step & {
	name: "Write version to .release file"
	run:  "echo '${{ steps.get-version.outputs.nextStrict }}-${{ steps.get-sha7.outputs.sha7 }}' > .release"
}

version: #ReleaseCommitStep: githubactions.#Step & {
	name: "Commit release changes"
	run: """
		git config user.name "github-actions[bot]"
		git config user.email "github-actions[bot]@users.noreply.github.com"
		git add .release manifests/
		git commit -m "release: ${{ steps.get-version.outputs.nextStrict }}"
		"""
}

version: #ReleasePushStep: githubactions.#Step & {
	name: "Push release commit"
	run:  "git push"
}

version: #CreateTagStep: githubactions.#Step & {
	name: "Create tag"
	uses: ghactions.#GithubScriptAction
	with: script: """
		github.rest.git.createRef({
		  owner: context.repo.owner,
		  repo: context.repo.repo,
		  ref: "refs/tags/v${{ steps.get-version.outputs.nextStrict }}",
		  sha: context.sha
		})
		"""
}
