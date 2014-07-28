#!/bin/bash

#
# Summary: Install the Python version of markdown and the mathJAX extension

sudo apt-get install python-markdown

mathjax_path=/tmp/mathjax

git clone git@github.com:mayoff/python-markdown-mathjax.git $mathjax_path

md_path=$(python -c "import markdown; print markdown.__path__[0]")

sudo cp $mathjax_path/mdx_mathjax.py $md_path/extensions/mathjax.py
sudo chmod 644 $md_path/extensions/mathjax.py

rm -rf $mathjax_path
