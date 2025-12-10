package github

// Core GitHub Actions workflow schema
#Workflow: {
	name: string
	on:   #On
	env?: {[string]: string}
	jobs: {[string]: #Job}
}

#On: {
	push?:         #PushTrigger
	pull_request?: #PullRequestTrigger
}

#PushTrigger: {
	branches?: [...string]
	"paths-ignore"?: [...string]
}

#PullRequestTrigger: {
	branches?: [...string]
	types?: [...string]
	"paths-ignore"?: [...string]
}

#Job: {
	name?:        string
	"runs-on":    string | *"ubuntu-latest"
	permissions?: #Permissions
	strategy?:    #Strategy
	services?: {[string]: #Service}
	steps: [...#Step]
	...
}

#Permissions: {
	contents?:   "read" | "write"
	"id-token"?: "read" | "write"
	packages?:   "read" | "write"
}

#Strategy: {
	matrix?: {[string]: [...string]}
}

#Service: {
	image: string
	env?: {[string]: string}
	ports?: [...string]
	options?: string
}

#Step: {
	name?: string
	id?:   string
	uses?: string
	run?:  string
	with?: {[string]: string | bool}
	env?: {[string]: string}
	if?: string
}
