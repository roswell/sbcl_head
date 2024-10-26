#sbcl_head
-include .env
export $(shell sed 's/=.*//' .env)

VERSION ?= $(shell date +%y.%-m.%-d)
TSV_FILE ?= sbcl-bin_uri.tsv
ROS_URI=https://raw.githubusercontent.com/roswell/sbcl_bin/master/

ORIGIN_URI=https://github.com/sbcl/sbcl
ORIGIN_REF=master
GITHUB=https://github.com/$(GITHUB_REPOSITORY)

SUFFIX ?=
SBCL_OPTIONS ?=--fancy
SBCL_PATCH ?=
LISP_IMPL ?= ros -L sbcl-bin without-roswell=t --no-rc run

ZSTD_BRANCH ?= v1.5.6

#version
version: web.ros
	@echo $(shell GH_USER=$(GH_USER) GH_REPO=$(GH_REPO) ros web.ros version) > $@
branch: version
	$(eval VERSION := $(shell cat version))
	VERSION=$(VERSION) ros build.ros branch > $@
latest-uris: web.ros
	ros web.ros latests
web.ros:
	curl -L -O $(ROS_URI)/web.ros
build.ros:
	curl -L -O $(ROS_URI)/build.ros
#tsv
tsv: web.ros
	TSV_FILE=$(TSV_FILE) ros web.ros tsv
upload-tsv: web.ros
	TSV_FILE=$(TSV_FILE) VERSION=$(VERSION) ros web.ros upload-tsv
download-tsv: web.ros
	VERSION=$(VERSION) ros web.ros get-tsv
#table
table: web.ros
	ros web.ros table
#archive
upload-archive: web.ros
	VERSION=$(VERSION) TARGET=$(ARCH) SUFFIX=$(SUFFIX) ros web.ros upload-archive
archive: build.ros
	VERSION=$(VERSION) ARCH=$(ARCH) SUFFIX=$(SUFFIX) ros build.ros archive
#tag
mirror-uris:
	curl -L http://sbcl.org/platform-table.html | grep http|awk -F '"' '{print $$2}'|grep binary > $@
mirror:
	METHOD=mirror ros run -l Lakefile

hash:
	git ls-remote --heads $(ORIGIN_URI) $(ORIGIN_REF) |sed -r "s/^([0-9a-fA-F]*).*/\1/" > hash

lasthash:
	curl -sSL -o lasthash $(GITHUB)/releases/download/files/hash || true

tag: hash lasthash web.ros
	@echo hash     = $(shell cat hash)
	@echo lasthash = $(shell cat lasthash)
	cp hash $(shell cat hash)
	diff -u hash lasthash || \
	( VERSION=$(VERSION) ros web.ros upload hash; \
	  VERSION=$(VERSION) ros web.ros upload $(shell cat hash); \
	  VERSION=files ros web.ros upload hash)

#zstd
zstd:
	git clone --depth 5 https://github.com/facebook/zstd --branch=$(ZSTD_BRANCH)

clean:
	rm -rf zstd
	rm -f verson branch
	ls |grep sbcl |xargs rm -rf
	rm -f hash lasthash

show:
	@echo VERSION=$(VERSION) ARCH=$(ARCH) BRANCH=$(BRANCH) SUFFIX=$(SUFFIX) HASH=$(HASH)
	cc -x c -v -E /dev/null || true
	cc -print-search-dirs || true

#sbcl
sbcl:
	git clone --depth 100 https://github.com/sbcl/sbcl --branch=master
	cd sbcl;git checkout `cat ../lasthash`
	@if [ -n "$(SBCL_PATCH)" ]; then\
		SBCL_PATCH="$(SBCL_PATCH)" $(MAKE) patch-sbcl; \
	fi

sbcl/version.lisp-expr: sbcl
	cd sbcl;echo '"$(VERSION)$(VERSION_SUFFIX)$(SUFFIX)"' > version.lisp-expr

compile-1: show sbcl
	cd sbcl;{ git describe  | sed -n -e 's/^.*-g//p' ; } 2>/dev/null > git_hash
	cat sbcl/git_hash
	rm -f sbcl/version.lisp-expr;VERSION=$(VERSION) $(MAKE) sbcl/version.lisp-expr
	mv sbcl/.git sbcl/_git || true
compile-config: compile-1
	cd sbcl;bash make-config.sh $(SBCL_OPTIONS) --arch=$(ARCH) --xc-host="$(LISP_IMPL)"
compile: compile-1
	bash -c "cd sbcl;bash make.sh $(SBCL_OPTIONS) --arch=$(ARCH) --xc-host='$(LISP_IMPL)'" \
	&& $(MAKE) compile-9
compile-9:
	cd sbcl;mv _git .git || true
	cd sbcl;bash make-shared-library.sh || true
	cd sbcl;bash run-sbcl.sh --eval "(progn (print *features*)(print (lisp-implementation-version))(terpri)(quit))"
	ldd sbcl/src/runtime/sbcl || \
	otool -L sbcl/src/runtime/sbcl || \
	readelf -d sbcl/src/runtime/sbcl || \
	true

archive:
	if [ -n "$$WIX" ] ; then \
	  VERSION=$(VERSION) ARCH=$(ARCH) OS=$(OS) SUFFIX=$(SUFFIX) make windows-archive; \
	else \
	  VERSION=$(VERSION) ARCH=$(ARCH) SUFFIX=$(SUFFIX) make unix-archive; \
	fi

latest-version: version lasthash
	$(eval VERSION := $(shell cat version))
	$(eval HASH := $(shell cat lasthash))
	@echo "set version $(VERSION):$(HASH)"
