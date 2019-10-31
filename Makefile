help:
	@echo "Please use \`make <target>' where <target> is one of:\n"
	@echo "   workshop   to prepare directory for upload to Steam Workshop."

workshop:
	@mkdir -p ./workshop/
	@mkdir -p ./workshop/images/
	@cp -R ./images/auto_join_icons.tex ./workshop/images/auto_join_icons.tex
	@cp -R ./images/auto_join_icons.xml ./workshop/images/auto_join_icons.xml
	@cp -R ./modicon.* ./workshop/
	@cp -R ./modinfo.lua ./workshop/
	@cp -R ./modmain.lua ./workshop/
	@cp -R ./scripts/ ./workshop/

.PHONY: workshop
