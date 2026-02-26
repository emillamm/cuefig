package steps

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions"

cache: #CacheStep: githubactions.#Step & {
	#Name:        string
	#Path:        string
	#Key:         string
	#RestoreKeys: string

	name: "Cache \(#Name)"
	uses: ghactions.#CacheAction
	with: {
		path:           #Path
		key:            #Key
		"restore-keys": #RestoreKeys
	}
}
