#!/bin/bash

set -e # This causes the script to exit if the `swift build` fails

pushd Server
swift build --disable-sandbox
swift run Run --auto-migrate &
ServerProcess=$!
set +e # This ensures that `kill $ServerProcess` is called if any of the next commands fails
popd

sleep 2

pushd Client
swift run &
ClientProcess=$!
popd

wait $ClientProcess

kill $ServerProcess
