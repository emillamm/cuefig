package k8s

import core "cue.dev/x/k8s.io/api/core/v1"

import batch "cue.dev/x/k8s.io/api/batch/v1"

import "list"

// spanner configuration
spanner: #JobName:  string | *"db-migrate"
spanner: #Instance: string | *"\(#Project)-prod-db"
spanner: #Database: string | *"\(#Name)-prod"
spanner: #Env: [...core.#EnvVar] | *[
	{
		name:  "POSTGRES_DATABASE"
		value: spanner.#Database
	},
	{
		name:  "POSTGRES_HOST"
		value: "localhost"
	},
	{
		name:  "POSTGRES_PORT"
		value: "5432"
	},
	{
		name:  "POSTGRES_USER"
		value: ""
	},
	{
		name:  "POSTGRES_PASS"
		value: ""
	},
]

// Sidecar init-container used for accessing spanner from container
spanner: #Sidecar: core.#Container & {
	name:          "pgadapter"
	restartPolicy: "Always"
	image:         "gcr.io/cloud-spanner-pg-adapter/pgadapter"
	ports: [
		{
			containerPort: 5432
		},
	]
	args: [
		"-p \(#Project)",
		"-i \(spanner.#Instance)",
		"-d \(spanner.#Database)",
		"-x",
	]
	resources: requests: {
		memory: "512Mi"
		cpu:    "250m"
	}
}

spanner: #MigrationJob: batch.#Job & {
	metadata: namespace: #Name
	metadata: name:      spanner.#JobName
	metadata: annotations: {
		"argocd.argoproj.io/hook":               "Sync"
		"argocd.argoproj.io/hook-delete-policy": "HookSucceeded"
		"argocd.argoproj.io/sync-wave":          "-1"
	}
	spec: ttlSecondsAfterFinished: 360
	spec: backoffLimit:            4
	spec: template: spec: {
		serviceAccountName: "deployment-sa"
		restartPolicy:      "Never"
		initContainers: [spanner.#Sidecar]
		containers: [
			{
				name:  "pgmigrate"
				image: "\(#Region)-docker.pkg.dev/\(#Project)/\(#Project)/\(#Name)-migrate:\(#ContainerVersion)"
				env: list.Concat([#CommonEnv, spanner.#Env])
			},
		]
	}
}
