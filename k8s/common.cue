package k8s

import core "cue.dev/x/k8s.io/api/core/v1"

#Name:             string
#Project:          string
#Region:           string
#ContainerVersion: string

#CommonEnv: [...core.#EnvVar] | *[
	{
		name:  "ENVIRONMENT"
		value: "prod"
	},
	{
		name:  "SERVICE_NAME"
		value: #Name
	},
	{
		name:  "SERVICE_VERSION"
		value: #ContainerVersion
	},
]
