#!/bin/bash
set -e
docker build -t infochimps/big-data-for-chimps .
docker run -t -i -v $PWD:/home/repro/big-data-for-chimps infochimps/big-data-for-chimps /bin/bash
