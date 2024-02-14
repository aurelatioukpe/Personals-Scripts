#!/bin/bash

gcc src/*.c -g3
valgrind ./a.out
