# Bash snippets

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
