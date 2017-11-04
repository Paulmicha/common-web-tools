# Bash snippets

## Multi-line variable

```sh
TEST_A="value a"

# See https://stackoverflow.com/questions/1167746/how-to-assign-a-heredoc-value-to-a-variable-in-bash
read -r -d '' TEST_B <<EOF
ls
pwd

ert='dfg'
echo "ert = \$ert"

if true; then
  echo $TEST_A
else
  echo 'no'
fi
EOF

eval "$TEST_B"
```
