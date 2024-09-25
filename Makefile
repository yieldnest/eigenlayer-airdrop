# Default target
.PHONY: all
all: clean install build

# Clean the cache and output directories
.PHONY: clean
clean:
	rm -rf cache out

# Install dependencies using forge
.PHONY: install
install:
	forge install

# Build the project using forge
.PHONY: build
build:
	forge build

# Compile the project using forge
.PHONY: compile
compile:
	forge compile

# Run the tests using forge
.PHONY: test
test:
	forge test

# Generate a coverage report
.PHONY: coverage
coverage:
	forge coverage

# Generate a coverage report and create an HTML report
.PHONY: coverage-report
coverage-report:
	forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

# Show the coverage report
.PHONY: coverage-show
coverage-show:
	npx http-server ./coverage

# Lint the Solidity files using forge fmt and solhint
.PHONY: lint
lint:
	forge fmt --check && solhint "{script,src,test}/**/*.sol"

# Format the Solidity files using forge fmt
.PHONY: format
format:
	forge fmt --root .


# make convert csv=script/input/ynETH.csv
csv ?= script/inputs/ynETH.csv
.PHONY: convert
convert:
	bash ./script/bash/convertCSVjson.sh ${csv}

# make deploy json=script/inputs/ynETH.json network=mainnet
json ?= script/inputs/ynETH.json
network ?= mainnet
.PHONY: deploy
deploy:
	forge script DeployEigenAirdrop --rpc-url ${network} --sig "run(string memory)" ${json}
