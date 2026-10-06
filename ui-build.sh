#!/bin/bash
# One-off helper: build the OM UI with the frontend-maven-plugin's own node/yarn
# under Git Bash (the Maven-driven path fails on Windows because yarn defaults
# to cmd.exe and the build scripts use POSIX expansions). The `antlr4` CLI the
# js-antlr script expects is not resolvable from node_modules on this checkout
# (the declared antlr4 dep is the runtime-only 4.9.2), so the parser is
# generated with the Java ANTLR 4.9.2 tool instead — same jar the ingestion
# image build uses.
set -e
cd "/d/eai/eai-metadata/openmetadata-ui/src/main/resources/ui"
NODE='/d/eai/eai-metadata/openmetadata-ui/${maven.multiModuleProjectDirectory}/target/frontend/node'
export PATH="$NODE:/c/Program Files/Eclipse Adoptium/jdk-21.0.9.10-hotspot/bin:$PATH"
YARN="node $NODE/yarn/dist/bin/yarn.js"

echo '=== antlr generation (java antlr-4.9.2) ==='
curl -sSL https://repo1.maven.org/maven2/org/antlr/antlr4/4.9.2/antlr4-4.9.2-complete.jar -o /tmp/antlr4.jar
rm -rf src/generated/antlr
java -jar /tmp/antlr4.jar -Dlanguage=JavaScript -Xexact-output-dir \
  -o src/generated/antlr \
  ../../../../../openmetadata-spec/src/main/antlr4/org/openmetadata/schema/*.g4
echo "antlr generated files: $(ls src/generated/antlr | wc -l)"

echo '=== vite build + brotli ==='
NODE_OPTIONS=--max-old-space-size=4096 APP_VERSION=2.0.0-SNAPSHOT $YARN run build:release
ls -la dist/index.html
echo UI_BUILD_OK
