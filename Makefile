SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

ANSIBLE_CACHE:=.ansible-cache

.DEFAULT_GOAL:=help
print-%: ; @echo $*=$($*)
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean: clean-ansible-cache clean-secrets ## Reset all generated files
	@true

.PHONY: playbook
playbook: plays/*.yaml vendor secrets
	@ansible-playbook \
		plays/hetzner.yaml \
		plays/hetzner_server.yaml \
		plays/compose_hosts.yaml

.PHONY: clean-ansible-cache
clean-ansible-cache:
	@rm -rf $(ANSIBLE_CACHE)

.PHONY: inventory
inventory: $(ANSIBLE_CACHE)/hosts vendor .env.secrets
$(ANSIBLE_CACHE)/hosts:
	@mkdir -p $(ANSIBLE_CACHE)
	@ansible-inventory --list | jq 'with_entries(select(.key != "_meta"))' > $(ANSIBLE_CACHE)/hosts

# Secret
.PHONY: secrets clean-secrets
secrets: .env.secrets
	@true
clean-secrets:
	@rm -f .env.secrets
.env.secrets: .env.secrets.tpl
	@op inject -f -i $< -o $@

# Vendor
.PHONY: clean-vendor
vendor:
	@vendir sync
clean-vendor:
	rm -rf vendor

.PHONY: lintfix
lintfix:
	@pre-commit run --all-files
