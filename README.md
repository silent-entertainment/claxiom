# claxiom
*A notebook-style in-browser editor for common lisp.*

The [`cl-notebook`](https://github.com/inaimathi/cl-notebook) project and forks of `cl-notebook` have been neglected for a couple of years, and issues have gone unresolved. This is the resurrection, with a new name, a new face and a new life. There are many new features planned for the near future. Some of the ideas are borrowed from other projects, but there are some surprises that are waiting to surface from the depths of the mind.

The decision to duplicate the `cl-notebook repository`, instead of forking it, was based on a few factors. My plan to diverge from the original project was the primary factor. Though the face of `cl-notebook` is very nice, I envision some changes that might not mesh with the original project or its forks. I also have some ideas about where I'd like to go with it that might be too extreme for the existing base and which essentially make it into a very different application. As a github novice, I was and still am completely unfamiliar with the customs of the community or proper etiquette, and I didn't want to be a nuisance to that existing base with my activities.

The name `claxiom` is a portmanteau of clever and axiom. Okay, I made that up as an afterthought. But isn't managing clever axioms what coding is all about? After all, we're just monkeys in disguise. In looking for a unique name for the project, I started with the popular convention of starting a common lisp project name with CL, and it evolved from there. *And, viola! Hey, Ma! I made a new word!*

And now we present the `claxiom notebook`,  with which you can record your stream of thoughts, code interactively with the flow, test those ideas and keep a running record of your progress, in a format that is easier on the eyes than plain text with all that __noisy__ syntax. The format also might make it quite convenient for sharing your thoughts.

## Reasoning

While looking for a `common lisp IDE`, I came across Jupyter Notebook. I was impressed, and it gave me some ideas for a current project. However, browsing the codebase gave me flashbacks of all of the reasons that I didn't like python *at all*. Besides, I wanted to work in `common lisp`, so naturally I looked for similar `common lisp` projects. 

I found a couple of related projects, but `cl-notebook` stood apart from the others. The codebase is very attractive and nicely documented where it needs to be, but the one feature that hooked me was the implementation of lispy html and parenscript **in the browser**. I had worked with `cl-who` and `parenscript` in the past, so I already had some ideas about such a desirable feature, before I had seen the implementation of it in the browser in `cl-notebook`. 

Hey, markdown is what it is, and it has its usefulness. However, in `Jupyter Notebook`, for example, if you want to hack the Notebook software, to add a nifty feature or to do something fancy, you're looking at dealing with different syntax for markdown, `HTML`, `javascript`, `python` and possibly other DSLs, such as templates. Switching back and forth from one syntax to the other requires too much energy that would be better used on the actual priorities. What would be the use of intentionally writing or reading a book that randomly switches among several different languages with varying conventions of grammar, inflection and punctuation? I'm exhausted just thinking about it.

It's like the WYSIWYG GUI designer, which might be great for a dedicated designer or for simple projects. However, just look at what it requires. Move your hand from the keyboard to the mouse. Point and click. Scan the screen for the icon. Point and click. Point, click and drag. Move your hand from the mouse back to the keyboard. Type, type, type. Move the hand back to the mouse. Scan. Point and click. Scan for the target menu. Point and click. Point and click. *Oops! Wrong menu.* Point and click. Scan. Scan. Scan. *Aargh! Where was that dang menu item again?* Point and click. *Ah! there it is.* Point and click. *Mystery meat icon. Mystery meat icon.* Point and hover. *Frick the frack? No, that wasn't it*... Back to the keyboard to write some code. Type, ty... *Oh, that widget should probably be resized.* Back to the mouse. Scan, point and click. Point, click and drag... Does it seem ludicrous yet? Now, you're a friggin' button pusher, and the buttons are poorly designed. It's not very efficient at all, when the alternative is to keep both hands on the keyboard, type in a line of code and have it appear on the screen near where you're looking already to see what you're typing. It sounds like a much better idea than the old way. If your rebuttal is that typing is too slow then you really need to take a typing course if you want to be a productive programmer.

Granted, different conventions for different purposes can be useful for the expression of specific ideas. However, even if you're an expert in every language that **might** be ideal for a particular project, switching back and forth between multiple representations is like a tax. If you have a reasonably sized team with individual specialists in each syntax who can and will provide a clean specification that effectively communicates the necessary requirements then each individual might be more productive in using a specialized language or tool, but it still will require more resources to glue it all together. It's that mythical man-month, complicated by all of the moving parts. If you're working solo or have a very small team, you can't afford the waste of time.

Why use so much boilerplate and bubblegum when everything can be done with a single uniform syntax, in common lisp? Then you only need to know the *structure* of an HTML document, the *structure* of a browser script and the *functions* for doing what you need to be done. Structure and function. That's it! And that makes the problem much simpler.

Now, arrange it as a client-server application with the browser as the client, which `cl-notebook` has done for us. Everything that can be done on the server without the latency being a problem can be written in that single syntax, and with parenscript you can write client code in lisp, too. If there are third-party javascript libraries that do what is needed then use them, of course. For smaller project-specific tasks, you can write it in javascript, *if you* **choose** *to do so*. I've written a lot of javascript very recently. All of that boilerplate and bubblegum gets *very* tedious, and I wouldn't want to write an entire application with it. With the server running, now you can take a break, go and sit on the couch with a cup of coffee and your tablet and proofread your thoughts. 

## Priorities

The first priority is to chase down all of the reported bug-related issues from all of the forks, squash the bugs and make it stable and functionally correct.

Next, we'll give the front end a slightly new face and implement at least a couple of new cell types. I'm going to keep the latter under wraps for now, because you'll think I'm a lunatic and because I don't want to make any promises that I can't keep, but it's going to be a wild ride.

Okay, I'm teasing! [Here's the scoop...](https://github.com/silent-entertainment/clidiom/blob/main/README.md) 

The second cell type to be added will be for a lispy XML DSL that is compiled from custom tags that are associated with custom styles in the client. In fact, there is probably such an animal available here, but I'll have to look at the available XML libraries and at XML features in the browser, because it has been quite some time since I have delved into it. The reasoning here is that writing the custom tags with the HTML generator would be more verbose than it needs to be, if I recall correctly, and that XML tags just make more sense. This feature ties into the ideas that are proposed in [`clidiom`](https://github.com/silent-entertainment/clidiom/blob/main/README.md), for which it would be *very* useful to see the ASTs that are generated from the prose and to tag the prose when the prose confuses the syntactic parser or the semantic parser, in addition to the compiler-generated lisp code, which of course could be handled by CodeMirror. Such a feature is also bound to have other uses, as well.

I realize that these plans for enhancements might be better placed in Projects, but I decided to offer a taste of the overall plan and motivation for this fork of `cl-notebook` for anyone who is looking for a view of `claxiom's` future from square one.

This fork materialized on November 17, 2020, so at the moment most of the code, documentation and presentation is from previous incarnations. Patience. I'm just getting started.

> Tools, of course, can be the subtlest of traps.
> One day I know I must smash the ~~emerald~~ Emacs.
>
> *with apologies to Neil Gaiman*

## This is now a pre-beta.
***Use it at your own risk and expect occasional minor explosions.***

## Usage

### With [`quicklisp`](http://www.quicklisp.org/beta/)

`claxiom` isn't in the `quicklisp` repository. As a workaround for using `ql:quickload` to load `claxiom` from a local copy, refer to section 4.1 of the [asdf manual](https://common-lisp.net/project/asdf/asdf.html). For my local system, I used the method of putting the line `(:directory "/home/username/path-to-claxiom-directory/")`in the file '/home/username/.config/common-lisp/source-registry.conf.d/50-username-lisp.conf', per section 4.1.

- Install a Common Lisp (I suggest [`sbcl`](http://www.sbcl.org/platform-table.html))
- Install [`quicklisp`](http://www.quicklisp.org/beta/)
- Hop into a Lisp and do `(ql:quickload :claxiom)`, followed by `(claxiom:main)`

### Binary

Download [this](http://static.inaimathi.ca/cl-notebook-binaries/), run it (if you downloaded the tarball instead of the naked binary, unpack it first, obviously)

_At the moment, we've only got binaries for 64-bit Linux. Submissions for other architectures welcome._

### With [`roswell`](https://github.com/roswell/roswell) and [`qlot`](https://github.com/fukamachi/qlot)-UNTESTED

These help you manage Common Lisp distributions. They are usefull not only for running claxiom, but for any other CL project, so consider them regardless of whether you want this project.

- Install [`roswell`](https://github.com/roswell/roswell)
- Install [`qlot`](https://github.com/fukamachi/qlot)
- Clone [`claxiom`](https://github.com/silent-entertainment/claxiom)

In the `claxiom directory you cloned to, do:

```
qlot install
qlot exec roswell/claxiom.ros --port 4242
```

**Once `claxiom` is Running**

Hop into a browser and go to `localhost:4242/` (or whatever port you chose)

A quick-ish, and now slightly out-of-date video demo is available [here](https://vimeo.com/97623064) to get you sort-of-started.

## Sytem Docs

### Building the Binary

#### With [`roswell`](https://github.com/roswell/roswell) and [`qlot`](https://github.com/fukamachi/qlot)

- Install [`roswell`](https://github.com/roswell/roswell)
- Install [`qlot`](https://github.com/fukamachi/qlot)
- Run `qlot exec ros build roswell/claxiom.ros` in the `claxiom` directory

   That will create a binary with the appropriate name that you can directly run on any machine of your OS and processor architecture.
- Grab your binary at `roswell/claxiom`.

This should work under Linux, OSX and Windows.

#### With [`buildapp`](https://www.xach.com/lisp/buildapp/)

In order to build the `claxiom` binary, you need to

- Install a Common Lisp (I suggest, and have only tried this with, [`sbcl`](http://www.sbcl.org/platform-table.html))
- Install [`quicklisp`](http://www.quicklisp.org/beta/)
- Install and build [`buildapp`](https://www.xach.com/lisp/buildapp/)
- Create an appropriate `build.manifest` file for loading `claxiom`
- Call `buildapp` with that `build.manifest` file, along with
	- a bunch of `--load-system` calls that include everything `claxiom` needs
    - an `--eval` call to `cl-notebook::read-statics` to include all the associated static files along with the binary
    - an `--entry` of `claxiom:main`
    - an `--output` of your choice of binary name (I suggest "`claxiom`")

That will create a binary with the appropriate name that you can directly run on any machine of your OS and processor architecture.

##### Linux

If you're on a Debian-based linux distro, there is a `build.lisp` and `build.sh` included in the `build/` subdirectory of this repo that do most of the above for you. All you need to do is make sure to install `sbcl`, then call `sh build.sh` in the `build` directory. This will result in a `buildapp` binary and a `claxiom` binary being generated for you. The `claxiom` binary can then be run on any linux machine _(of the same CPU architecture)_ without worrying about installing a Lisp.

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
