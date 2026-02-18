// cmhc-retrofit project identity
package kb

import "quicue.ca/kg/ext@v0"

project: ext.#Context & {
	"@id":        "https://quicue.ca/project/cmhc-retrofit"
	name:         "cmhc-retrofit"
	description:  "Construction program management — CMHC deep retrofit (NHCF) and Ontario Greener Homes processing platform"
	module:       "quicue.ca/cmhc-retrofit@v0"
	repo:         "https://github.com/quicue/cmhc-retrofit"
	license:      "Apache-2.0"
	status:       "active"
	cue_version:  "v0.15.3"
	uses: [
		{"@id": "https://quicue.ca/pattern/struct-as-set"},
		{"@id": "https://quicue.ca/pattern/three-layer"},
	]
	knows: [
		{"@id": "https://quicue.ca/concept/dependency-graph"},
		{"@id": "https://quicue.ca/concept/construction-management"},
		{"@id": "https://quicue.ca/concept/energy-efficiency"},
	]
}
