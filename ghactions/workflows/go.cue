package workflows

go: mixins: #WithGo: #BuildWorkflow & {
	#CacheConfig: {
		#BuildCacheSteps: [
			#steps.go.#ModCacheStep,
			#steps.go.#BuildCacheStep,
		]
	}
}

go: #TestPublic: #TestWorkflow &
	mixins.#WithDevbox &
	go.mixins.#WithGo

go: #TestPrivate: #TestWorkflow &
	mixins.#WithAppToken &
	mixins.#WithDevbox &
	go.mixins.#WithGo

go: #PublishServicePrivate: #PublishWorkflow &
	mixins.#WithAppToken &
	mixins.#WithDevbox &
	go.mixins.#WithGo &
	mixins.release.#WithCueGenModify &
	mixins.release.#WithPushContainers &
	mixins.release.#WithPushVersionTag

go: #PublishLibraryPublic: #PublishWorkflow &
	mixins.#WithDevbox &
	go.mixins.#WithGo &
	mixins.release.#WithPushVersionTag

go: #PublishLibraryPrivate: #PublishWorkflow &
	mixins.#WithAppToken &
	mixins.#WithDevbox &
	go.mixins.#WithGo &
	mixins.release.#WithPushVersionTag
