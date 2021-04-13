TEST_FILES?=$(shell git ls-tree -r --name-only HEAD t)

test:
	@prove -Ilib -v ${TEST_FILES}
