GIT_LATEST_TAG = $$(git describe --abbrev=0)
MODINFO_VERSION = $$(grep '^version.*=' < modinfo.lua | awk -F'= ' '{ print $$2 }' | tr -d '"')

# Source: https://stackoverflow.com/a/10858332
__check_defined = $(if $(value $1),, $(error Undefined $1$(if $2, ($2))))
check_defined = $(strip $(foreach 1,$1, $(call __check_defined,$1,$(strip $(value 2)))))

help:
	@printf "Please use 'make <target>' where '<target>' is one of:\n\n"
	@echo "   assets         to pack images"
	@echo "   gitrelease     to commit modinfo.lua and CHANGELOG.md + add a new tag"
	@echo "   install        to install the mod"
	@echo "   ldoc           to generate an LDoc documentation"
	@echo "   lint           to run code linting"
	@echo "   modicon        to pack modicon"
	@echo "   release        to update version"
	@echo "   test           to run Busted tests"
	@echo "   testcoverage   to print the tests coverage report"
	@echo "   testlist       to list all existing tests"
	@echo "   uninstall      to uninstall the mod"
	@echo "   workshop       to prepare the Steam Workshop directory"

assets:
	@:$(call check_defined, DS_KTOOLS_KTECH)
	@${DS_KTOOLS_KTECH} images/auto_join_icons/* . --atlas images/auto_join_icons.xml

gitrelease:
	@echo "Latest Git tag: ${GIT_LATEST_TAG}"
	@echo "Modinfo version: ${MODINFO_VERSION}\n"

	@printf '1/5: Resetting (git reset)...'
	@git reset > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@printf '2/5: Adding and commiting modinfo.lua...'
	@git add modinfo.lua > /dev/null 2>&1
	@git commit -m 'Update modinfo: version and description' > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@printf '3/5: Adding and commiting CHANGELOG.md...'
	@git add CHANGELOG.md > /dev/null 2>&1
	@git commit -m "Update CHANGELOG.md: release ${MODINFO_VERSION}" > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@printf "4/5: Creating a signed tag (v${MODINFO_VERSION})..."
	@git tag -s "v${MODINFO_VERSION}" -m "Release v${MODINFO_VERSION}" > /dev/null 2>&1 && echo ' Done' || echo ' Error'
	@echo "5/5: Verifying tag (v${MODINFO_VERSION})...\n"
	@git verify-tag "v${MODINFO_VERSION}"

install:
	@:$(call check_defined, DST_MODS)
	@rsync -az \
		--exclude '.*' \
		--exclude 'CHANGELOG.md' \
		--exclude 'Makefile' \
		--exclude 'README.md' \
		--exclude 'busted.out' \
		--exclude 'config.ld' \
		--exclude 'description.txt*' \
		--exclude 'doc/' \
		--exclude 'images/auto_join_icons/' \
		--exclude 'luacov*' \
		--exclude 'modicon.png' \
		--exclude 'modicon/' \
		--exclude 'readme/' \
		--exclude 'spec/' \
		--exclude 'workshop/' \
		. \
		"${DST_MODS}/dst-mod-auto-join/"

ldoc:
	@find ./doc/* -type f -not -name Dockerfile -not -name docker-stack.yml -not -wholename ./doc/ldoc/ldoc.css -delete
	@ldoc .

lint:
	@EXIT=0; \
		printf "Luacheck:\n\n"; luacheck . --exclude-files="here/" || EXIT=$$?; \
		printf "\nPrettier (Markdown):\n\n"; prettier --check ./**/*.md || EXIT=$$?; \
		printf "\nPrettier (XML):\n\n"; prettier --check ./**/*.xml || EXIT=$$?; \
		printf "\nPrettier (YAML):\n\n"; prettier --check ./**/*.yml || EXIT=$$?; \
		exit $${EXIT}

modicon:
	@:$(call check_defined, DS_KTOOLS_KTECH)
	@${DS_KTOOLS_KTECH} ./modicon.png . --atlas ./modicon.xml --square

release:
	@:$(call check_defined, MOD_VERSION)
	@echo "Version: ${MOD_VERSION}\n"

	@printf '1/2: Updating modinfo version...'
	@sed -i "s/^version.*$$/version = \"${MOD_VERSION}\"/g" ./modinfo.lua && echo ' Done' || echo ' Error'
	@printf '2/2: Syncing LDoc release code occurrences...'
	@find . -type f -regex '.*\.lua' -exec sed -i "s/@release.*$$/@release ${MOD_VERSION}/g" {} \; && echo ' Done' || echo ' Error'

test:
	@busted . && luacov-console . && luacov-console -s

testcoverage:
	@luacov-console . && luacov-console -s

testlist:
	@busted --list . | awk '{$$1=""}1' | awk '{ gsub(/^[ \t]+|[ \t]+$$/, ""); print }'

uninstall:
	@:$(call check_defined, DST_MODS)
	@rm -Rf "${DST_MODS}/dst-mod-auto-join/"

workshop:
	@rm -Rf ./workshop/
	@mkdir -p ./workshop/images/
	@cp -R ./LICENSE ./workshop/LICENSE
	@cp -R ./images/auto_join_icons.tex ./workshop/images/auto_join_icons.tex
	@cp -R ./images/auto_join_icons.xml ./workshop/images/auto_join_icons.xml
	@cp -R ./modicon.tex ./workshop/
	@cp -R ./modicon.xml ./workshop/
	@cp -R ./modinfo.lua ./workshop/
	@cp -R ./modmain.lua ./workshop/
	@cp -R ./scripts/ ./workshop/

.PHONY: assets ldoc modicon workshop
