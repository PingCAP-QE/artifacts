Images  = $(shell gawk '/^\# hub/{printf "-t %s " , $$2}' $@/Dockerfile )

products_bases := tidb-base tikv-base pd-base tools-base tiflash-base
pingcap-base :
	docker buildx build $@ $(Images) --push --platform=linux/amd64,linux/arm64

$(products_bases) : pingcap-base
	docker buildx build $@ $(Images) --push --platform=linux/amd64,linux/arm64

all_bases : pingcap-base $(products_bases)

.PHONY : pingcap-base $(products_bases) all_bases
