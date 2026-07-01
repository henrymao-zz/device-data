.PHONY: all fetch prepare build upload clean

# --- Configuration ----------------------------------------------------------
BRANCH        := 202405
UPSTREAM_REPO := https://github.com/sonic-net/sonic-buildimage
PPA           := ppa:henrymao/ubuntu-nos
GPG_KEY       := A30250A69E5B4C27139CD7898AFC7E4A6437DFA0
DEBEMAIL      := henry.mao@canonical.com
DEBFULLNAME   := Henry Mao
RELEASE       ?= $(shell lsb_release -cs)

PACKAGE_NAME    := $(shell dpkg-parsechangelog -S Source -l debian/changelog)
VERSION         := $(shell dpkg-parsechangelog -S Version -l debian/changelog)
UPSTREAM_VERSION := $(shell echo $(VERSION) | sed 's/-[0-9]*$$//')

BUILD_DIR := build
SRC_DIR   := $(BUILD_DIR)/$(PACKAGE_NAME)-$(UPSTREAM_VERSION)
UPSTREAM_TMP := sonic-buildimage-tmp

# --- Top-level target -------------------------------------------------------
all: build upload

# --- fetch: download only the device/ dir from the upstream branch ---------
fetch:
	@echo "==> Fetching device/ from $(UPSTREAM_REPO) branch $(BRANCH)..."
	rm -rf $(UPSTREAM_TMP) device
	git clone --filter=blob:none --sparse --branch $(BRANCH) --depth=1 \
		$(UPSTREAM_REPO) $(UPSTREAM_TMP)
	cd $(UPSTREAM_TMP) && git sparse-checkout set device
	cp -a $(UPSTREAM_TMP)/device ./device
	rm -rf $(UPSTREAM_TMP)
	@echo "==> device/ ready ($$(ls device | wc -l) vendor dirs)."

# --- prepare: assemble the source tree in build/ ---------------------------
prepare: fetch
	@echo "==> Preparing source tree in $(SRC_DIR) ..."
	rm -rf $(BUILD_DIR)
	mkdir -p $(SRC_DIR)/device
	# Flatten device/<vendor>/<platform> -> device/<platform> (dereference symlinks)
	cp -r -L device/*/* $(SRC_DIR)/device/
	# Copy debian packaging
	cp -a debian $(SRC_DIR)/debian
	# Set distribution and timestamp on the copied changelog
	sed -i 's/UNRELEASED/$(RELEASE)/' $(SRC_DIR)/debian/changelog
	NOW=$$(date -R); \
	sed -i "0,/^ -- .*>  .*/s/^ -- .*>  .*/ -- $(DEBFULLNAME) <$(DEBEMAIL)>  $$NOW/" \
		$(SRC_DIR)/debian/changelog
	@echo "==> Prepared $(SRC_DIR)."

# --- build: build the source package ---------------------------------------
build: prepare
	@echo "==> Building source package $(PACKAGE_NAME) $(VERSION) ..."
	# Create the orig tarball (upstream source, excluding debian/)
	tar -cJf $(BUILD_DIR)/$(PACKAGE_NAME)_$(UPSTREAM_VERSION).orig.tar.xz \
		--exclude='$(PACKAGE_NAME)-$(UPSTREAM_VERSION)/debian' \
		-C $(BUILD_DIR) $(PACKAGE_NAME)-$(UPSTREAM_VERSION)
	cd $(SRC_DIR) && \
		DEBEMAIL="$(DEBEMAIL)" DEBFULLNAME="$(DEBFULLNAME)" \
		debuild -S -sa -k$(GPG_KEY)
	@echo "==> Source package built in $(BUILD_DIR)/."

# --- upload: dput the changes file to the PPA ------------------------------
upload: build
	@echo "==> Uploading to $(PPA) ..."
	dput $(PPA) $(BUILD_DIR)/$(PACKAGE_NAME)_$(VERSION)_source.changes
	@echo "==> Upload complete."

# --- clean ------------------------------------------------------------------
clean:
	rm -rf $(BUILD_DIR) $(UPSTREAM_TMP) device
