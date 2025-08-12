PKG_VERSION := $(shell yq e ".version" manifest.yaml)
PKG_ID := $(shell yq e ".id" manifest.yaml)
MANAGER_SRC := $(shell find ./manager -name '*.rs') manager/Cargo.toml manager/Cargo.lock
# $(VERSION_CORE) was previously obtained from git submodule, now hardcoded

.DELETE_ON_ERROR:

all: verify

clean:
	rm -f $(PKG_ID).s9pk
	rm -f docker-images/*.tar
	rm -f scripts/*.js

verify: $(PKG_ID).s9pk
	@start-sdk verify s9pk $(PKG_ID).s9pk
	@echo " Done!"
	@echo "   Filesize: $(shell du -h $(PKG_ID).s9pk) is ready"

# for rebuilding just the arm image.
arm:
	@rm -f docker-images/x86_64.tar
	@ARCH=aarch64 $(MAKE) -s

# for rebuilding just the x86 image.
x86:
	@rm -f docker-images/aarch64.tar
	@ARCH=x86_64 $(MAKE) -s

$(PKG_ID).s9pk: manifest.yaml assets/compat/* docker-images/aarch64.tar docker-images/x86_64.tar instructions.md scripts/embassy.js
ifeq ($(ARCH),aarch64)
	@echo "start-sdk: Preparing aarch64 package ..."
else ifeq ($(ARCH),x86_64)
	@echo "start-sdk: Preparing x86_64 package ..."
else
	@echo "start-sdk: Preparing Universal Package ..."
endif
	@start-sdk pack

install:
	@if [ ! -f ~/.embassy/config.yaml ]; then echo "You must define \"host: http://server-name.local\" in ~/.embassy/config.yaml config file first."; exit 1; fi
	@echo "\nInstalling to $$(grep -v '^#' ~/.embassy/config.yaml | cut -d'/' -f3) ...\n"
	@[ -f $(PKG_ID).s9pk ] || ( $(MAKE) && echo "\nInstalling to $$(grep -v '^#' ~/.embassy/config.yaml | cut -d'/' -f3) ...\n" )
	@start-cli package install $(PKG_ID).s9pk

docker-images/aarch64.tar: Dockerfile docker_entrypoint.sh manager/target/aarch64-unknown-linux-musl/release/bitcoind-manager manifest.yaml check-rpc.sh check-synced.sh actions/*
ifeq ($(ARCH),x86_64)
else
	mkdir -p docker-images
	docker buildx build --tag start9/$(PKG_ID)/main:$(PKG_VERSION) --build-arg ARCH=aarch64 --build-arg PLATFORM=arm64 --platform=linux/arm64 -o type=docker,dest=docker-images/aarch64.tar .
endif

docker-images/x86_64.tar: Dockerfile docker_entrypoint.sh manager/target/x86_64-unknown-linux-musl/release/bitcoind-manager manifest.yaml check-rpc.sh check-synced.sh actions/*
ifeq ($(ARCH),aarch64)
else
	mkdir -p docker-images
	docker buildx build --tag start9/$(PKG_ID)/main:$(PKG_VERSION) --build-arg ARCH=x86_64 --build-arg PLATFORM=amd64 --platform=linux/amd64 -o type=docker,dest=docker-images/x86_64.tar .
endif

manager/target/aarch64-unknown-linux-musl/release/bitcoind-manager: $(MANAGER_SRC)
	docker run --rm -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/manager:/home/rust/src messense/rust-musl-cross:aarch64-musl cargo build --release

manager/target/x86_64-unknown-linux-musl/release/bitcoind-manager: $(MANAGER_SRC)
	docker run --rm -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/manager:/home/rust/src messense/rust-musl-cross:x86_64-musl cargo build --release

scripts/embassy.js: scripts/**/*.ts
	@echo "Bundling TypeScript files with Deno..."
	@echo "Deno version: $$(deno --version 2>/dev/null || echo 'Deno not found')"
	@echo "Current directory: $$(pwd)"
	@echo "Checking embassy.ts file..."
	@test -f scripts/embassy.ts || (echo "ERROR: scripts/embassy.ts not found" && exit 1)
	@echo "Attempting to bundle with deno (up to 5 attempts)..."
	@{ i=1; \
	while [ $$i -le 5 ]; do \
		echo "Attempt $$i of 5..."; \
		if deno bundle scripts/embassy.ts scripts/embassy.js; then \
			echo "Successfully created scripts/embassy.js"; \
			break; \
		else \
			echo "Attempt $$i failed"; \
			if [ $$i -lt 5 ]; then \
				echo "Retrying in 10 seconds..."; \
				sleep 10; \
			else \
				echo "All attempts failed. Checking for network issues..."; \
				echo "Contents of scripts directory:"; \
				ls -la scripts/; \
				echo "Contents of scripts/services directory:"; \
				ls -la scripts/services/ 2>/dev/null || echo "services directory not found"; \
				exit 1; \
			fi; \
		fi; \
		i=`expr $$i + 1`; \
	done; }
	@test -f scripts/embassy.js || (echo "ERROR: Failed to create scripts/embassy.js after all attempts" && exit 1)
