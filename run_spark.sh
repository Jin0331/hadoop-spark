#! /bin/bash

sudo docker run -dit --name $2 --network $1 kmubigdata/ubuntu-spark:latest /bin/bash
