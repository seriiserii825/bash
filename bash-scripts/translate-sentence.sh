#!/bin/bash
# Translates an entered sentence to a chosen language using trans-shell

# choose language to translate
read -p "Choose the language to translate: " lang
read -p "Enter the sentence to translate: " sentence

trans -b :$lang "$sentence" | tr -d '\n'  

