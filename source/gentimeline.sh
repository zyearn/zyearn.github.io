#!/bin/zsh

t=`date "+%Y-%m-%d %H:%M"`; gsed -i '8i\> '${t} blog/timeline/index.markdown
vim blog/timeline/index.markdown
