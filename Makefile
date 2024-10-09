#sbcl_head
-include .env
export $(shell sed 's/=.*//' .env)

VERSION ?= $(shell date +%y.%-m.%-d)
TSV_FILE ?= sbcl-bin_uri.tsv
WEB_ROS_URI=https://raw.githubusercontent.com/roswell/sbcl_bin/master/web.ros

ORIGIN_URI=https://github.com/sbcl/sbcl
ORIGIN_REF=master
GITHUB=https://github.com/roswell/sbcl_head

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
hash:
	git ls-remote --heads $(ORIGIN_URI) $(ORIGIN_REF) |sed -r "s/^([0-9a-fA-F]*).*/\1/" > hash

lasthash: web.ros
	curl -sSL -o lasthash $(GITHUB)/releases/download/files/hash || touch lasthash

tag: hash web.ros
	($(MAKE) lasthash  && diff -u hash lasthash) || \
	( VERSION=$(VERSION) ros web.ros upload-hash; \
	  VERSION=$(VERSION) ros web.ros upload-hash; \
	  VERSION=files ros web.ros upload-hash)

clean:
	rm -f hash lasthash
