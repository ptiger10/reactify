#!/bin/bash

original=$(pwd)
for dir in example/*/web; do
    cd $dir
    mkdir -p netlify
    cp index.html netlify
    cp favicon.ico netlify
    if [ -f ./style.css ]
        then cp style.css netlify
    fi
    cd ..
    pub upgrade reactify
    cd web
    dart2js main.dart -o netlify/main.dart.js
    cd $original
done
