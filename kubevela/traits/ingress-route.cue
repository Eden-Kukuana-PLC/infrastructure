"ingress-route": {
//	alias: ""
	annotations: {}
	attributes: {
		appliesToWorkloads: []
		conflictsWith: []
		podDisruptive:   false
		workloadRefPath: ""
	}
	description: "My ingress route trait."
	labels: {}
	type: "trait"
	spec: {
		name: "ingress-route"
	}
}

template: {
	patch: {}
	parameter: {
		routes: [...{
			kind: *"Rule" | string
			match: string
			services: [...{
				name: string
				port: int
			}]
		}]
	}
	outputs: ingress: {
		apiVersion: "traefik.io/v1alpha1"
		kind: 			"IngressRoute"
		metadata: {
			name: context.name
			namespace: context.namespace
		}
		spec: {
			name: context.name
			routes: [
				for route in parameter.routes {
					kind: route.kind
					match: route.match
					services: [
						for service in route.services {
							name: service.name
							port: service.port
						}
					]
				}
			]
		}
	}

}

