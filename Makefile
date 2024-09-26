# Default values
csv ?= script/inputs/ynETH.csv
json ?= script/inputs/ynETH.json
network ?= mainnet
deployerAccountName := $(shell grep '^DEPLOYER_ACCOUNT_NAME=' .env | cut -d '=' -f2)
deployerAddress := $(shell grep '^DEPLOYER_ADDRESS=' .env | cut -d '=' -f2)

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
	forge test -vvv

# Create a gas snapshot
.PHONY: snapshot
snapshot:
	forge snapshot

# Generate a coverage report
.PHONY: coverage
coverage:
	forge coverage

# Generate a coverage report and create an HTML report
.PHONY: coverage-report
coverage-report:
	forge coverage --report lcov && genhtml lcov.info --output-directory coverage

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
.PHONY: convert
convert:
	bash ./script/bash/convertCSVjson.sh ${csv}

# make simulate json=script/inputs/ynETH.json network=mainnet
.PHONY: simulate
simulate:
	forge script DeployEigenAirdrop --sig "run(string memory)" ${json} --rpc-url ${network}

# make deploy json=script/inputs/ynETH.json network=mainnet
.PHONY: deploy
deploy:
	forge script DeployEigenAirdrop --sig "run(string memory)" ${json} --rpc-url ${network} --account ${deployerAccountName} --sender ${deployerAddress} --slow --broadcast --verify
