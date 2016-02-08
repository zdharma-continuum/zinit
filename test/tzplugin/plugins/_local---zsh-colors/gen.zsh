# Run this after updating template.zsh
# It is easiest to just check in these files I think
for color in black red green yellow blue magenta cyan white
do
  cp --update $(dirname $0)/template.zsh $(dirname $0)/$color
done
