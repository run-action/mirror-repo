.PHONY: test

test:
	bash -n scripts/lib.sh scripts/configure-ssh.sh scripts/mirror-repository.sh test/parse-target-url.bats test/mirror-repository.bats
	shellcheck -x scripts/lib.sh scripts/configure-ssh.sh scripts/mirror-repository.sh
	yq '.' action.yml >/dev/null
	bats test
