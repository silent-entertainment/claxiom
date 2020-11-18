# claxiom
*A notebook-style in-browser editor for Common Lisp.*

The cl-notebook project and forks of cl-notebook have been neglected for a few years. This is the resurrection, with a new name and a new life. There are many new features planned for the near future. Some of the ideas are borrowed from other projects, but there are some surprises that are waiting to surface from the depths of the mind.

The name claxiom is a portmanteau of clever and axiom. Okay, I made that up as an afterthought. But isn't managing clever axioms what coding is all about? In looking for a unique name for the project, I started with the popular convention of starting a common lisp project name with CL, and it evolved from there. *And, viola! Hey, Ma! I made a word!*

And now we present the ***claxiom notebook***,  with which you can record your stream of thoughts and code as they flow, test those ideas and keep a running record of your progress, in a format that is easier on the eyes than plain text with __noisy__ syntax. The format also might make it handy for sharing your thoughts.

## Reasoning

In looking for an IDE, I came across Jupyter Notebook. I was impressed, and it gave me some ideas for a current project. However, browsing the codebase gave me flashbacks of all of the reasons that I didn't like Python *at all*. Besides, I wanted to work in Common Lisp, so naturally I looked for similar Common Lisp projects. 

I found a couple of related projects, but cl-notebook stood apart from the others. The codebase is very attractive and nicely documented where it needs to be, but the one feature that hooked me was the availability of lispy html and parenscript **in the browser**. I had worked with cl-who and parenscript in the past, so I already had some ideas about such a desirable feature, before I had seen the implementation of it in the browser in cl-notebook. 

Hey, markdown is what it is, and it has its usefulness. However, in Jupyter Notebook, for example, if you want to hack the Notebook software, to add a nifty feature or to do something fancy, you're looking at dealing with different syntax for markdown, HTML, javascript, Python and possibly other DSLs, such as templates. Switching back and forth from one syntax to the other requires too much energy that would be better used on the actual priorities. Why use so much boilerplate and bubblegum when everything can be done with a single syntax, in Common Lisp? Then you only need to know the structure of an HTML document and the structure of a browser script. That's it! And that makes the problem much simpler. 

## Priorities

The first priority is to chase down all of the reported bug-related issues from all of the forks and squash the bugs.

This fork materialized on November 17, 2020, so at the moment most of the code, documentation and presentation is from previous lives. Patience. I'm just getting started.

> Tools, of course, can be the subtlest of traps.
> One day I know I must smash the ~~emerald~~ Emacs.
>
> *with apologies to Neil Gaiman*

## This is now a pre-beta.
***Use it at your own risk, and expect occasional minor explosions.***

## Usage

### With [`quicklisp`](http://www.quicklisp.org/beta/)

- Install a Common Lisp (I suggest [`sbcl`](http://www.sbcl.org/platform-table.html))
- Install [`quicklisp`](http://www.quicklisp.org/beta/)
- Hop into a Lisp and do `(ql:quickload :cl-notebook)`, followed by `(cl-notebook:main)`

NOTE: cl-notebook is no longer in the quicklisp repository. I saw something about the possibility that it would be removed due to bugs that stemmed from changes to the API of a dependency. As a workaround, to use quicklisp with a local copy refer to section 4.1 of the [asdf manual](https://common-lisp.net/project/asdf/asdf.html). In a future update, the system name, package name and related filenames will be changed to claxiom.

### Binary

Download [this](http://static.inaimathi.ca/cl-notebook-binaries/), run it (if you downloaded the tarball instead of the naked binary, unpack it first, obviously)

_At the moment, we've only got binaries for 64-bit Linux. Submissions for other architectures welcome._

### With [`roswell`](https://github.com/roswell/roswell) and [`qlot`](https://github.com/fukamachi/qlot)

These help you manage Common Lisp distributions. They are usefull not only for running claxiom, but for any other CL project, so consider them regardless of whether you want this project.

- Install [`roswell`](https://github.com/roswell/roswell)
- Install [`qlot`](https://github.com/fukamachi/qlot)
- Clone [cl-notebook](https://github.com/Inaimathi/cl-notebook)

In the `cl-notebook` directory you cloned to, do:

```
qlot install
qlot exec roswell/cl-notebook.ros --port 4242
```

**Once `cl-notebook` is Running**

Hop into a browser and go to `localhost:4242/` (or whatever port you chose)

A quick-ish, and now slightly out-of-date video demo is available [here](https://vimeo.com/97623064) to get you sort-of-started.

## Sytem Docs

### Building the Binary

#### With [`roswell`](https://github.com/roswell/roswell) and [`qlot`](https://github.com/fukamachi/qlot)

- Install [`roswell`](https://github.com/roswell/roswell)
- Install [`qlot`](https://github.com/fukamachi/qlot)
- Run `qlot exec ros build roswell/cl-notebook.ros` in the `cl-notebook` directory

   That will create a binary with the appropriate name that you can directly run on any machine of your OS and processor architecture.
- Grab your binary at `roswell/cl-notebook`.

This should work under Linux, OSX and Windows.

#### With [`buildapp`](https://www.xach.com/lisp/buildapp/)

In order to build the `cl-notebook` binary, you need to

- Install a Common Lisp (I suggest, and have only tried this with, [`sbcl`](http://www.sbcl.org/platform-table.html))
- Install [`quicklisp`](http://www.quicklisp.org/beta/)
- Install and build [`buildapp`](https://www.xach.com/lisp/buildapp/)
- Create an appropriate `build.manifest` file for loading `cl-notebook`
- Call `buildapp` with that `build.manifest` file, along with
	- a bunch of `--load-system` calls that include everything `cl-notebook` needs
    - an `--eval` call to `cl-notebook::read-statics` to include all the associated static files along with the binary
    - an `--entry` of `cl-notebook:main`
    - an `--output` of your choice of binary name (I suggest "`cl-notebook`")

That will create a binary with the appropriate name that you can directly run on any machine of your OS and processor architecture.

##### Linux

If you're on a Debian-based linux distro, there is a `build.lisp` and `build.sh` included in the `build/` subdirectory of this repo that do most of the above for you. All you need to do is make sure to install `sbcl`, then call `sh build.sh` in the `build` directory. This will result in a `buildapp` binary and a `cl-notebook` binary being generated for you. The `cl-notebook` binary can then be run on any linux machine _(of the same CPU architecture)_ without worrying about installing a Lisp.

##### OS X

TODO - patches welcome, since I'm not an OS X user

##### Windows

TODO - patches welcome, since I'm not a Windows user

### Source Deployment
### Usage
#### Keybindings
#### Building Programs/Executables
#### Notebook Exporters
#### Cell Compilers

## License

[AGPL3](https://www.gnu.org/licenses/agpl-3.0.html) (also found in the included copying.txt)

*Short version:*

Do whatever you like, BUT afford the same freedoms to anyone you give this software or derivative works (yes, this includes the new stuff you do) to, and anyone you expose it to as a service.

This project uses [CodeMirror](http://codemirror.net/) as a front-end editor. CodeMirror [is released](http://codemirror.net/#community) under the [MIT Expat license](http://codemirror.net/LICENSE).

## Credits

This project uses:
- [`nativesortable`](https://github.com/bgrins/nativesortable)
- [Code Mirror](http://codemirror.net/)
- [Genericons](http://genericons.com/)
- [Blob.js](https://github.com/eligrey/Blob.js) and [FileSave.js](https://github.com/eligrey/FileSaver.js)
- A spinner generated from [here](http://preloaders.net/en/letters_numbers_words)
- [`anaphora`](http://www.cliki.net/anaphora)
- [`alexandria`](http://common-lisp.net/project/alexandria/)
- [`parenscript`](http://common-lisp.net/project/parenscript/)
- [`cl-who`](http://weitz.de/cl-who/)
- [`quicklisp`](http://www.quicklisp.org/beta/)
- [`buildapp`](http://www.xach.com/lisp/buildapp/)
