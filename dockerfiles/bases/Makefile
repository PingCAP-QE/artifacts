Images  = $(shell gawk '/^\# hub/{printf "-t %s " , $$2}' $@/Dockerfile )

all_bases := pingcap-base tidb-base tikv-base pd-base tools-base tiflash-base
$(all_bases) :
	docker buildx build $@ $(Images) --push --platform=linux/amd64,linux/arm64

.PHONY : $(all_bases)
