#!/bin/bash
#![allow(warnings)] /*
OUT=/tmp/$(echo "rust-script-$(date +%s)$RANDOM")
rustc "$0" -o ${OUT}
exec ${OUT} $@ || exit $? */

fn main() {
    println!("Hello Script from Rust!");
}