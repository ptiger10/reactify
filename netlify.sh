#!/bin/bash

original=$(pwd)
for dir in example/*/web; do
    cd $dir
    mkdir -p netlify
    cp index.html netlify
    if [ -f ./style.css ]
        then cp style.css netlify
    fi
    dart2js main.dart -o netlify/main.dart.js
    cd $original
done
