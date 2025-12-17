package workflows

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions/steps"

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

#TestWorkflow: #Workflow & {
	name: "Test"
	on: pull_request: types: ["opened", "reopened", "synchronize"]
}

#PublishWorkflow: #Workflow & {
	name: "Publish"
	on: push: {}
}
