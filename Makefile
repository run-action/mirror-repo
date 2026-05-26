.PHONY: test

test:
	bash -n scripts/lib.sh scripts/configure-ssh.sh scripts/mirror-repository.sh scripts/verify-host-keys.sh test/parse-target-url.bats test/mirror-repository.bats
	shellcheck -x scripts/lib.sh scripts/configure-ssh.sh scripts/mirror-repository.sh scripts/verify-host-keys.sh
	yq '.' action.yml .github/workflows/*.yml >/dev/null
	bats test
