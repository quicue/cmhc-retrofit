// Knowledge graph index — comprehension-derived, never hand-maintained
package kb

import "quicue.ca/kg/aggregate@v0"

_index: aggregate.#KGIndex & {
	project: "cmhc-retrofit"

	decisions: {}
	insights:  {}
	rejected:  {}
	patterns:  {}
}

// W3C projections — export via: cue export . -e provenance.graph
_provenance:  aggregate.#Provenance & {index:   _index}
_annotations: aggregate.#Annotations & {index:  _index}
_catalog:     aggregate.#DatasetEntry & {index:  _index, context: project}
