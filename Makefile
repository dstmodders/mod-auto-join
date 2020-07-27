# Source: https://stackoverflow.com/a/10858332
__check_defined = $(if $(value $1),, $(error Undefined $1$(if $2, ($2))))
check_defined = $(strip $(foreach 1,$1, $(call __check_defined,$1,$(strip $(value 2)))))

help:
	@printf "Please use 'make <target>' where '<target>' is one of:\n\n"
	@echo "   assets         to pack images"
	@echo "   install        to install the mod"
	@echo "   ldoc           to generate an LDoc documentation"
	@echo "   lint           to run code linting"
	@echo "   modicon        to pack modicon"
	@echo "   test           to run Busted tests"
	@echo "   testcoverage   to print the tests coverage report"
	@echo "   testlist       to list all existing tests"
	@echo "   uninstall      to uninstall the mod"
	@echo "   workshop       to prepare the Steam Workshop directory"

assets:
	@:$(call check_defined, DS_KTOOLS_KTECH)
	@${DS_KTOOLS_KTECH} images/auto_join_icons/* . --atlas images/auto_join_icons.xml

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
