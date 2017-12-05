# Bash snippets

## Remote execution + handling Arbitrary Arguments

```sh
# See https://unix.stackexchange.com/questions/87405/how-can-i-execute-local-script-on-remote-machine-and-include-arguments
# -> https://unix.stackexchange.com/a/326672

# With bash or ksh as /bin/sh
runRemote() {
  local args script

  script=$1; shift

  # generate eval-safe quoted version of current argument list
  printf -v args '%q ' "$@"

  # pass that through on the command line to bash -s
  # note that $args is parsed remotely by /bin/sh, not by bash!
  ssh user@remote-addr "bash -s -- $args" < "$script"
}

# With Any POSIX-Compliant /bin/sh
runRemote() {
  local script=$1; shift
  local args
  printf -v args '%q ' "$@"
  ssh user@remote-addr "bash -s" <<EOF

  # pass quoted arguments through for parsing by remote bash
  set -- $args

  # substitute literal script text into heredoc
  $(< "$script")

EOF
}

# Usage (for either of the above)

# if your time should be three arguments
runRemote /var/www/html/ops1/sysMole -time Aug 18 18

# if your time should be one string
runRemote /var/www/html/ops1/sysMole -time "Aug 18 18"
```

## Split string using delimiter to array

```sh
# See https://stackoverflow.com/questions/10586153/split-string-into-an-array-in-bash
IFS=', ' read -r -a array <<< "$string"

# To access an individual element:
echo "${array[0]}"

# To iterate over the elements:
for element in "${array[@]}"
do
  echo "$element"
done

# To get both the index and the value:
for index in "${!array[@]}"
do
  echo "$index ${array[index]}"
done

# The last example is useful because Bash arrays are sparse. In other words, you can delete an element or add an element and then the indices are not contiguous.
unset "array[1]"
array[42]=Earth

# To get the number of elements in an array:
echo "${#array[@]}"

# As mentioned above, arrays can be sparse so you shouldn't use the length to get the last element. Here's how you can in Bash 4.2 and later:
echo "${array[-1]}"

# in any version of Bash (from somewhere after 2.05b):
echo "${array[@]: -1:1}"

# Larger negative offsets select farther from the end of the array. Note the space before the minus sign in the older form. It is required
```

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
