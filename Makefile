#sbcl_head
-include .env
export $(shell sed 's/=.*//' .env)

VERSION ?= $(shell date +%y.%-m.%-d)
TSV_FILE ?= sbcl-bin_uri.tsv
WEB_ROS_URI=https://raw.githubusercontent.com/roswell/sbcl_bin/master/web.ros

ORIGIN_URI=https://github.com/sbcl/sbcl
ORIGIN_REF=master
GITHUB=https://github.com/$(GITHUB_REPOSITORY)

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
	curl -L -O $(WEB_ROS_URI)
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
#tag
mirror-uris:
	curl -L http://sbcl.org/platform-table.html | grep http|awk -F '"' '{print $$2}'|grep binary > $@
mirror:
	METHOD=mirror ros run -l Lakefile

hash:
	git ls-remote --heads $(ORIGIN_URI) $(ORIGIN_REF) |sed -r "s/^([0-9a-fA-F]*).*/\1/" > hash

lasthash: web.ros
	curl -sSL -o lasthash $(GITHUB)/releases/download/files/hash || touch lasthash

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
#sbcl
compile: show
	@[ -n "$(VERSION)" ] || (echo version should be set; false)
	rm -rf sbcl
	git clone --depth 100 https://github.com/sbcl/sbcl --branch=master
	cd sbcl;git checkout `cat ../lasthash`
	cd sbcl;echo '"$(VERSION)-daily"' > version.lisp-expr
	cd sbcl;bash make.sh $(SBCL_OPTIONS) --arch=$(ARCH) --xc-host="$(LISP_IMPL)" || true
	cd sbcl;bash run-sbcl.sh --eval "(progn (print *features*)(terpri)(quit))"
archive:
	if [ -n "$$WIX" ] ; then \
	  VERSION=$(VERSION) ARCH=$(ARCH) OS=$(OS) SUFFIX=$(SUFFIX) make -f $(MAKEFILE_JUSTNAME) windows-archive; \
	else \
	  VERSION=$(VERSION) ARCH=$(ARCH) SUFFIX=$(SUFFIX) make -f $(MAKEFILE_JUSTNAME) unix-archive; \
	fi

unix-archive: show
	ln -s sbcl `pwd`/sbcl-$(VERSION)-$(ARCH)-$(OS)$(SUFFIX)
	./sbcl/binary-distribution.sh sbcl-$(VERSION)-$(ARCH)-$(OS)$(SUFFIX)
	rm -f sbcl-$(VERSION)-$(ARCH)-$(OS)$(SUFFIX)-binary.tar.bz2
	bzip2 sbcl-$(VERSION)-$(ARCH)-$(OS)$(SUFFIX)-binary.tar

windows-archive: show
	cd sbcl;bash make-windows-installer.sh
	echo $(VERSION)-$(ARCH)-windows$(SUFFIX)-binary > sbcl/output/version.txt
	cd sbcl/output;"$$WIX/bin/light" sbcl.wixobj \
	  -ext "$$WIX/bin/WixUIExtension.dll" -cultures:en-us \
	  -out sbcl-`cat version.txt`.msi
	cd sbcl/output;mv sbcl-`cat version.txt`.msi ../..


upload-archive: show
	VERSION=$(VERSION) TARGET=$(ARCH) SUFFIX=$(SUFFIX) ros web.ros upload-archive

latest-version: lasthash version
	$(eval VERSION := $(shell cat version))
	$(eval HASH := $(shell cat lasthash))
	@echo "set version $(VERSION):$(HASH)"
