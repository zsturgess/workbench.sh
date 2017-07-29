# Workbench.sh

[![Build Status](https://travis-ci.org/zsturgess/workbench.sh.svg?branch=master)](https://travis-ci.org/zsturgess/workbench.sh)

Workbench.sh is a bash script designed to bring some of the power of the [Salesforce Workbench](https://workbench.developerforce.com/) to the command-line. It can be used to run SOQL queries and describe objects via the Force.com REST API.

Workbench.sh is a creation of Zac Sturgess. See also the [list of contributors](https://github.com/zsturgess/workbench.sh/graphs/contributors).

## Installation

Workbench.sh requires a command-line version of `curl` >= 7.18.0. You can check your local version by running `curl -V`.

It's recommended to use [the latest tagged release](https://github.com/zsturgess/workbench.sh/releases) of Workbench.sh, just in case something gets broken in development.

Simply download the `workbench.sh` file to a location of your choosing, make it executable (`chmod u+x workbench.sh`), and run it (`./workbench.sh`).

Workbench.sh will help you set up your default config file the first time you attempt to use it.

## Usage

Workbench.sh comes with extensive on-board help:

```
./workbench.sh -h
```

## License

This project is under the MIT license. See the [complete license](LICENSE):

    LICENSE


## Reporting an issue or a feature request

Issues and feature requests are tracked in the [Github issue tracker](https://github.com/zsturgess/workbench.sh/issues).
