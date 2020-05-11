# The Porcelain programming language

![forthebadge](https://forthebadge.com/images/badges/contains-cat-gifs.svg)

```csharp
sub main()
    (match w
        case 'a'     1
        case 0xF     2
        case 8       3
        otherwise    4) where w = 5 + 3
```

Porcelain is my little programming language, born for educational purposes and
to escape boredom.

In this repository you will find its main compiler, `porcelainc`.

The whole design has as main principles:

```text
- Ease of syntax rules and overall little language complexity, allowing easy
  implementation, usage and an easy understanding of the language. It will
  never support AST macros, D's mixins, turing complete templates or compile
  time function execution, features than arguably make languages complex for
  little use cases.

- A flexible syntax, without excessive sound like semicolons and without any
  type of tabulation enforcement. A programming language is a tool and no tool
  is good if it enforces a style of working, like python tabulation rules, or
  if it clutters the work with unnecessary signs that just make the language
  more difficult to work with.
```

## Documentation

+ [Authors of the compiler](AUTHORS.md)
+ [License of the compiler, as the exceptions](LICENSE.md)

## Building the source code

Make sure you have installed:

* `git` (only if you are using it to download the source)
* `meson`, a python-based build system used by the compiler
* `dmd`, `ldc2`, `gdc` or another D compiler, the latest the better.

With all of that covered, just clone the [source](source) with `git` if you dont
have it already with:

```bash
git clone https://github.com/TheStr3ak5/porcelain.git
cd porcelain
```

And next lets build and install the source with:

```bash
meson build         # Configure porcelainc and create the directory for build
cd build            # Enter the directory
ninja && ninja test # Build the final executable and test against some examples
ninja install       # Install on the directory configured for the system
```
