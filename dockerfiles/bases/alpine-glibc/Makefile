MATRIX   ?= matrix.yaml
SKAFFOLD ?= skaffold.yaml
REGISTRY ?= ghcr.io/pingcap-qe/bases

.PHONY: generate check build

# Regenerate skaffold.yaml from matrix.yaml.
generate:
	@tmp=$$(mktemp); \
		yq -o=json $(MATRIX) | python3 generate-profiles.py > $$tmp; \
		mv $$tmp $(SKAFFOLD)

# Fail if skaffold.yaml is out of date (used in CI).
check:
	@yq -o=json $(MATRIX) | python3 generate-profiles.py | diff -u $(SKAFFOLD) - >/dev/null \
		|| { echo "ERROR: $(SKAFFOLD) is out of date; run 'make generate'" >&2; exit 1; }

# Build/push one matrix entry, e.g.
#   make build PROFILE=3.22_glibc-2.30
build:
	@test -n "$(PROFILE)" || { echo "usage: make build PROFILE=3.22_glibc-2.30" >&2; exit 1; }
	skaffold build \
		--build-concurrency=1 \
		--default-repo=$(REGISTRY) \
		--profile=$(PROFILE)
