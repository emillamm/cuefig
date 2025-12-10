package github

import ( "github.com/emillamm/templates/schemas/github"

	// =============================================================================
	// Go-specific workflow components
	// =============================================================================
)

// Standard Go setup using actions/setup-go
#GoSetup: {
	_version: string | *"1.24.x"

	// Matrix configuration that can be composed into a job
	goMatrix: {
		strategy: matrix: "go-version": [_version]
		...
	}

	steps: [
		#GoSetupStep & {_goVersion: "${{ matrix.go-version }}"},
		{
			name: "Install dependencies"
			run:  "go get ."
		},
	]
}

// Go test step
#GoTest: {
	steps: [{
		name: "Run tests"
		run:  "go test ./..."
	}]
}

// Private Go modules configuration
#GoPrivateModules: {
	_goprivate: string

	env: {
		GOPRIVATE: _goprivate
	}
}
