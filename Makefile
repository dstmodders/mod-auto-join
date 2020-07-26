help:
	@printf "Please use 'make <target>' where '<target>' is one of:\n\n"
	@echo "   workshop   to prepare the Steam Workshop directory"

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
