# Simple Makefile to wrap deps-only installers

.PHONY: install-all install-noir install-scarb install-bb install-sncast verify uninstall

install-all: install-noir install-scarb install-bb install-sncast
	@echo "All toolchain installers executed."

install-noir:
	@./scripts/install-noir.sh || (echo "install-noir failed" && exit 1)

install-scarb:
	@./scripts/install-scarb.sh || (echo "install-scarb failed" && exit 1)

install-bb:
	@./scripts/install-barretenberg.sh || (echo "install-barretenberg failed" && exit 1)

install-sncast:
	@./scripts/install-sncast.sh || (echo "install-sncast failed" && exit 1)

verify:
	@./scripts/verify.sh

uninstall:
	@./scripts/uninstall.sh
URL=https://ztarknet-madara.d.karnot.xyz
ACCOUNT_NAME=ztarknet
ACCOUNT_CLASS_HASH=0x01484c93b9d6cf61614d698ed069b3c6992c32549194fc3465258c2194734189
FEE_TOKEN_ADDRESS=0x1ad102b4c4b3e40a51b6fb8a446275d600555bd63a95cdceed3e5cef8a6bc1d

account-create:
	sncast account create \
		--class-hash $(ACCOUNT_CLASS_HASH) \
		--type oz \
		--url $(URL) \
		--name $(ACCOUNT_NAME)

account-topup:
	@echo "Getting account address..."
	@ADDR=$$(sncast account list 2>/dev/null | grep -A 10 "$(ACCOUNT_NAME)" | grep "address:" | awk '{print $$2}'); \
	if [ -z "$$ADDR" ]; then \
		echo "Error: Account '$(ACCOUNT_NAME)' not found."; \
		echo "Run 'make account-create' first to create the account."; \
		exit 1; \
	fi; \
	echo "Account address: $$ADDR"; \
	cd admin && TOPUP_ADDRESS=$$ADDR npm run topup

account-deploy:
	sncast account deploy \
		--url $(URL) \
		--name $(ACCOUNT_NAME)

account-balance:
	sncast balance \
		--token-address $(FEE_TOKEN_ADDRESS) \
		--url $(URL)

## Install dependencies (Automated)

install-sncast:
	-./scripts/install-sncast.sh

install-noir:
	-./scripts/install-noir.sh

install-scarb:
	-./scripts/install-scarb.sh

install-barretenberg:
	-./scripts/install-barretenberg.sh

install-all: install-sncast install-noir install-scarb install-barretenberg
	@echo ""
	@echo "================================"
	@echo "Installation Summary"
	@echo "================================"
	@echo ""
	@command -v sncast >/dev/null 2>&1 && echo "✓ sncast: $$(sncast --version 2>&1 | head -1)" || echo "✗ sncast: Not installed (manual setup required)"
	@command -v nargo >/dev/null 2>&1 && echo "✓ nargo: $$(nargo --version 2>&1 | head -1)" || echo "✗ nargo: Not installed"
	@command -v scarb >/dev/null 2>&1 && echo "✓ scarb: $$(scarb --version 2>&1 | head -1)" || echo "✗ scarb: Not installed"
	@command -v bb >/dev/null 2>&1 && echo "✓ bb: $$(bb --version 2>&1)" || echo "✗ bb: Not installed"
	@command -v npm >/dev/null 2>&1 && echo "✓ npm: $$(npm --version)" || echo "✗ npm: Not installed"
	@echo ""


setup:
	./scripts/setup.sh
