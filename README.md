stansent
============


[![Build
Status](https://travis-ci.org/trinker/stansent.svg?branch=master)](https://travis-ci.org/trinker/stansent)
[![Coverage
Status](https://coveralls.io/repos/trinker/stansent/badge.svg?branch=master)](https://coveralls.io/r/trinker/stansent?branch=master)
<a href="https://img.shields.io/badge/Version-0.0.1-orange.svg"><img src="https://img.shields.io/badge/Version-0.0.1-orange.svg" alt="Version"/></a>
</p>
**stansent** wraps Stanford's sentiment tagger in a way that makes the
process easier to get set up.


Table of Contents
============

-   [Installation](#installation)
-   [Contact](#contact)
-   [Getting Started](#getting-started)

Installation
============


To download the development version of **stansent**:

Download the [zip
ball](https://github.com/trinker/stansent/zipball/master) or [tar
ball](https://github.com/trinker/stansent/tarball/master), decompress
and run `R CMD INSTALL` on it, or use the **pacman** package to install
the development version:

    if (!require("pacman")) install.packages("pacman")
    pacman::p_load_gh("trinker/stansent")

Contact
=======

You are welcome to: 
* submit suggestions and bug-reports at: <https://github.com/trinker/stansent/issues> 
* send a pull request on: <https://github.com/trinker/stansent/> 
* compose a friendly e-mail to: <tyler.rinker@gmail.com>


Getting Started
===============

After installing use:

    get_setup()

to make sure your Java version is of the right version and
[coreNLP](http://nlp.stanford.edu/software/corenlp.shtml) is set up in
the right location.

After that you can use:

    if (!require("pacman")) install.packages("pacman"); library(pacman)
    p_load_gh("trinker/stansent")

    sentiment_stanford(c(
        "I am very angry about this text.",  
        "I am now happier about the text string"
    ))

    ## 
    ## Analyzing text for sentiment...

    ## [1] -0.5  0.0