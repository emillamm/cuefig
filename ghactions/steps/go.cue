package steps

go: #ModCacheStep: cache.#CacheStep & {
	#Name: "Go modules"
	#Path: "/home/runner/go/pkg/mod"
	#Key:  "go-cache-${{ runner.os }}-${{ hashFiles('go.sum') }}"
	#RestoreKeys: """
		go-mod-cache-${{ runner.os }}-
		go-mod-cache-
		"""
}

go: #BuildCacheStep: cache.#CacheStep & {
	_hashPattern: string | *"**/*.go"
	#Name:        "Go internal (to speed up tests)"
	#Path:        "/home/runner/.cache/go-build"
	#Key:         "go-cache-${{ runner.os }}-${{ hashFiles('\(_hashPattern)', 'go.sum') }}"
	#RestoreKeys: """
		go-cache-${{ runner.os }}-
		go-cache-
		"""
}
