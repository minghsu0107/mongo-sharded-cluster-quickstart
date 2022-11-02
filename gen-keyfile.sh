#!/bin/bash

openssl rand -base64 756 > ./mongosecret
chmod 400 ./mongosecret