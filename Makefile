help:
	@printf "Please use 'make <target>' where '<target>' is one of:\n\n"
	@echo "   install     to install the mod"
	@echo "   uninstall   to uninstall the mod"
	@echo "   workshop    to prepare the Steam Workshop directory"

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

.PHONY: workshop
