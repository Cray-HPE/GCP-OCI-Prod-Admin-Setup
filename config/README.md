# Sigstore Config

This directory contains Jobs that need to be run **only one time** to configure Sigstore infrastructure.

Unless you're trying to set up a new instance of Sigstore with new infrastructure, you don't have to worry about running anything in here!

This directory contains:
* `trillian/createdb`: This Job configures the backend CloudSQL database with the correct schema for Trillian to use, based on the Trillian [resetdb](https://github.com/google/trillian/blob/2053c7648b44d5de45863c3ad12550b511ad6a14/scripts/resetdb.sh) script.
