SCLANG=/Applications/SuperCollider/SuperCollider.app/Contents/MacOS/sclang

random-composer: install-extensions kill-existing-server ## Random Composer
	${SCLANG} gui.scd

.PHONY: install-extensions
install-extensions:
	cp extensions/*.sc ~/Library/Application\ Support/SuperCollider/Extensions
	cp classes/*.sc ~/Library/Application\ Support/SuperCollider/Extensions

.PHONY: kill-existing-server
kill-existing-server:
	 ps auxwww | grep scsynth | grep -v grep | awk '// { print $$2 }' | xargs -I {} kill {}

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
