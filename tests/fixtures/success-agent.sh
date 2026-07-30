#!/usr/bin/env bash

set -Eeuo pipefail

cat >/dev/null
mkdir -p tests
cat > tests/example-test.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
test -f tests/example-test.sh
EOF
chmod +x tests/example-test.sh
printf 'fixture agent completed\n'
