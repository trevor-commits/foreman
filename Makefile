# foreman — convenience targets for the template repo itself.
# Downstream projects may delete this file; hooks/pre-push also runs scripts/verify.sh
# when present.

.PHONY: verify test
verify:
	bash scripts/verify.sh

test: verify
