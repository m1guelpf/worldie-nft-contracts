all: install build
# Install forge dependencies (not needed if submodules are already initialized).
install:; forge install
# Build contracts and inject the Poseidon library.
build:; forge build
# Update forge dependencies.
update:; forge update
# Deploy contracts
deploy:; forge create WorldieNFT --interactive
