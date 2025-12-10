package conf

#conf: [_]: T={
	get: *T.value | T.default
	...
}
