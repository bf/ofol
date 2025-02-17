-- mod-version:3
local syntax = require "lib.syntax"

syntax.add {
  name = "Containerfile",
  files = { "^Containerfile$", "^Dockerfile$", "%.[cC]ontainerfile$", "%.[dD]ockerfile$" },
  comment = "#",
  patterns = {
    { pattern = "#.*\n", type = "comment" },

    -- Functions
    { pattern = { "%[", "%]" }, type = "string" },

    -- Literals
    { pattern = "%sas%s", type = "literal" },
    { pattern = "--platform=", type = "literal" },
    { pattern = "--chown=", type = "literal" },

    -- Symbols
    { pattern = "[%a_][%w_]*", type = "symbol" },
  },
  symbols = {
    ["FROM"] = "keyword",
    ["ARG"] = "keyword2",
    ["ENV"] = "keyword2",
    ["RUN"] = "keyword2",
    ["ADD"] = "keyword2",
    ["COPY"] = "keyword2",
    ["WORKDIR"] = "keyword2",
    ["USER"] = "keyword2",
    ["LABEL"] = "keyword2",
    ["EXPOSE"] = "keyword2",
    ["VOLUME"] = "keyword2",
    ["ONBUILD"] = "keyword2",
    ["STOPSIGNAL"] = "keyword2",
    ["HEALTHCHECK"] = "keyword2",
    ["SHELL"] = "keyword2",
    ["ENTRYPOINT"] = "function",
    ["CMD"] = "function",
  },
}



-- MIT License

-- Copyright (c) 2022 FilBot3

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- # lite-xl-language-containerfile

-- ## Overview

-- Lite-XL Syntax Highlighting for Containerfile/Dockerfile.
-- It's a very basic Lite-XL Syntax Highlighting plugin.
-- It definitely could use some extra love to make some more intelligent detection.

-- A `Containerfile` is provided as an example of what it would look like when the plugin is installed.

-- ## Requirements

-- * Lite-XL v2.0.5 or newer

-- ## Usage

-- Clone the project to the User Module Directory.
-- Refer to the [Lite-XL Documentation: Usage](https://lite-xl.com/?/documentation/usage) for more information on where this is for your system.
-- The example given here is for Linux/MacOS.

-- ```bash
-- git clone https://github.com/FilBot3/lite-xl-language-containerfile.git ~/.config/lite-xl/plugins/language_containerfile
-- ```

-- Restart Lite-XL, and it should start working.

-- ## Screenshots

-- ![Lite-XL Containerfile Syntax Highlighting](./docs/lite-xl-screenshot.png)
