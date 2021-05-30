-include .env
export $(shell sed 's/=.*//' .env)

VERSION=`date +%y.%-m.%-d`
LAST_VERSION=`ros web.ros version`
ORIGIN_URI=https://github.com/sbcl/sbcl
ORIGIN_REF=master
GITHUB=https://github.com/roswell/sbcl_head

hash:
	git ls-remote --heads $(ORIGIN_URI) $(ORIGIN_REF) |sed -r "s/^([0-9a-fA-F]*).*/\1/" > hash

lasthash:
	curl -sSL -o lasthash $(GITHUB)/releases/download/$(LAST_VERSION)/hash

upload-hash: hash lasthash
	diff -u hash lasthash || VERSION=$(VERSION) ros web.ros upload-hash

version:
	echo $(VERSION)
clean:
	rm hash lasthash
