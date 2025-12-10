package steps

import "cue.dev/x/githubactions"

import "github.com/emillamm/cuefig/ghactions"

go: #ModCacheStep: githubactions.#Step & {
	name: "Cache Go modules"
	uses: ghactions.#CacheAction
	with: {
		path: "/home/runner/go/pkg/mod"
		key:  "go-cache-${{ runner.os }}-${{ hashFiles('go.sum') }}"
		"restore-keys": """
			go-mod-cache-${{ runner.os }}-
			go-mod-cache-
			"""
	}
}

go: #BuildCacheStep: githubactions.#Step & {
	_hashPattern: string | *"**/*.go"
	name:         "Cache Go internal cache (to speed up tests)"
	uses:         ghactions.#CacheAction
	with: {
		path: "/home/runner/.cache/go-build"
		key:  "go-cache-${{ runner.os }}-${{ hashFiles('\(_hashPattern)', 'go.sum') }}"
		"restore-keys": """
			go-cache-${{ runner.os }}-
			go-cache-
			"""
	}
}
