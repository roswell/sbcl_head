#sbcl_head
-include .env
export $(shell sed 's/=.*//' .env)

VERSION=`date +%y.%-m.%-d`
LAST_VERSION=`ros web.ros version`
ORIGIN_URI=https://github.com/sbcl/sbcl
ORIGIN_REF=master
GITHUB=https://github.com/roswell/sbcl_head
TSV_FILE=sbcl-bin_uri.tsv

hash:
	git ls-remote --heads $(ORIGIN_URI) $(ORIGIN_REF) |sed -r "s/^([0-9a-fA-F]*).*/\1/" > hash

lasthash: web.ros
	curl -sSL -o lasthash $(GITHUB)/releases/download/$(LAST_VERSION)/hash

tag: hash web.ros
	($(MAKE) lasthash  && diff -u hash lasthash) || \
	( VERSION=$(VERSION) ros web.ros upload-hash; \
	  VERSION=files ros web.ros upload-hash)

tsv: web.ros
	TSV_FILE=$(TSV_FILE) ros web.ros tsv

upload-tsv: web.ros
	TSV_FILE=$(TSV_FILE) ros web.ros upload-tsv

version: web.ros
	@echo $(LAST_VERSION) > version
web.ros:
	curl -L -O https://raw.githubusercontent.com/roswell/sbcl_bin/master/web.ros

clean:
	rm -f hash lasthash

table:
	ros web.ros table
