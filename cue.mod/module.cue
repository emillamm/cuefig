module: "github.com/emillamm/cuefig"
language: {
	version: "v0.15.1"
}
source: {
	kind: "git"
}
deps: {
	"cue.dev/x/githubactions@v0": {
		v:       "v0.3.0"
		default: true
	}
	"cue.dev/x/k8s.io@v0": {
		v:       "v0.6.0"
		default: true
	}
}
