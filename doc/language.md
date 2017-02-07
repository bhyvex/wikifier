# Language

Wikifier's source language is designed to be easily legible by the naked eye.

* [Language](#language)
  * [Syntax](#syntax)
    * [Comments](#comments)
    * [Escaping](#escaping)
  * [Blocks](#blocks)
      * [Nameless blocks](#nameless-blocks)
      * [Named blocks](#named-blocks)
      * [Model shorthand](#model-shorthand)
      * [Data types](#data-types)
  * [Variables](#variables)
    * [Assignment](#assignment)
    * [Retrieval](#retrieval)
    * [Formatted variables](#formatted-variables)
    * [Attributes](#attributes)
    * [Conditionals](#conditionals)
    * [Interpolable variables](#interpolable-variables)
    * [Special variables](#special-variables)
  * [Text formatting](#text-formatting)
    * [Basic formatting](#basic-formatting)
    * [Variables](#variables-1)
    * [Links](#links)
    * [References](#references)
    * [Characters](#characters)

## Syntax

The Wikifier source language is [parsed hierarchically](parsing.md). In other
words, the source is divided into components (called [blocks](#blocks)) which
then are responsible for parsing their inner contents. The master parser is
concerned only with the most basic syntax:
* Dividing the source into [blocks](#blocks)
* Stripping [comments](#comments)
* [Variable assignment](#assignment)
* [Conditionals](#conditionals)

Further parsing is provided by:
* [Text formatter](#text-formatting)
* [Map](blocks.md#map) base block type
* [List](blocks.md#list) base block type
* Block types may implement custom parsing

### Comments

Currently only C-style block comments are supported:
```
/* Some text */
```

These can span multiple lines and be nested within each other:
```
/*
    Line one
    Line two has /* a nested comment */
*/
```

### Escaping

Some characters must be escaped for literal use. The escape character (`\`)
denotes the character immediately following it as escaped.

**Anywhere** in a document, these characters MUST be escaped for literal use:

| Character | Reason for escape                 |
| -----     | -----                             |
| `\`       | Escape character                  |
| `{`       | Starts a [block](#blocks)         |
| `}`       | Terminates a [block](#blocks)     |

Within [**formatted text**](#text-formatting), the following characters must be
escaped in addition to those listed above:

| Character | Reason for escape                                         |
| -----     | -----                                                     |
| `[`       | Starts a [text formatting](#text-formatting) token        |
| `]`       | Terminates a [text formatting](#text-formatting) token    |

Within [**maps**](blocks.md#map) and [**lists**](blocks.md#list), these
characters must also be escaped:

| Character | Must be escaped in                    | Reason for escape     |
| -----     | -----                                 | -----                 |
| `;`       | Map keys and values, list values      | Terminates a value    |
| `:`       | Map keys                              | Terminates a key      |

**Brace-escape**. Sometimes it may be desirable to disable all parsing within a
particular block. This is especially useful for things like
[`code{}`](blocks.md#code), [`html{}`](blocks.md#html), and
[`format{}`](blocks.md#format) because then you do not have to escape every
instance of special characters like `{`, `}`, and `\`. It works as long as there
is a closing bracket `{` to correspond with every opening bracket `}`. To enable
brace-escape mode, open and close the block with double curly brackets:

```javascript
code {{
    ae.removeLinesInRanges = function (ranges) {
        if (!ranges || !ranges.length)
            return;
        for (var i = biggest; i >= smallest; i--) {
            if (!rows[i]) {
                if (typeof lastLine != 'undefined') {
                    editor.session.doc.removeFullLines(i + 1, lastLine);
                    lastLine = undefined;
                }
                continue;
            }
            if (typeof lastLine == 'undefined') lastLine = i;
        }
    };
}}
```

## Blocks

The fundamental component of the Wikifier language is the **block**.
The syntax for a block is as follows:

```
Type [Name] { Content }
```
* __Type__ - The kind of block. The block type provides a unique
  function. For instance, [`imagebox{}`](blocks.md#imagebox) displays a bordered
  image with a caption and link to the full size original.
* __Name__ - Depending on its type, a block may have a name. Each block type
  may use the name field for a different purpose. For example,
  [`infobox{}`](blocks.md#infobox) uses the field to display a title bar across
  the top of the info table.
* __Content__ - Inside the block, there may be additional blocks and/or text.
  Each block handles the content within differently. Some may treat it as
  plain text, while others may do further parsing on it.

See [Blocks](blocks.md) for a list of built-in block types.

#### Nameless blocks

The `[block name]` field may be omitted for block types that do not require it.

```
blocktype {
    ...
}
```

Example
```
imagebox {
    desc:   [[Foxy]], supreme librarian;
    align:  left;
    file:   foxy2.png;
    width:  100px;
}
```

#### Named blocks

For block types that support a `[block name]` field, it should follow the block
type and be delimited by square brackets `[` and `]`. The name field may
contain additional square brackets inside it without the need for the escape
character (`\`) as long as the number of opening brackets and closing brackets
are equal. Otherwise, they must be escaped.

```
blocktype [block name] {
    ...
}
```

Example
```
sec [Statistics] {
    NoTrollPlzNet Library's online division currently hosts
    [@stats.site.articles] articles.
}
```

#### Model shorthand

Wikifier has a special syntax for using [**models**](models.md). Write them like
any block, except prefix the model name with a dollar sign (`$`).

```
$my_model {
    option1: Something;
    option2: Another option;
}
```
Note: From within the model source, those options can be retrieved with
`@m.option1` and `@m.option2`.

Same as writing the long form:
```
model [my_model] {
    option1: Something;
    option2: Another option;
}
```

#### Data types

[`map{}`](blocks.md#map) provides a key-value map datatype. It serves as the
base of many other block types. Likewise, [`list{}`](blocks.md#list) provides an
array datatype.

## Variables

Wikifier supports string, boolean, and block variables.

### Assignment

**String** variables look like this:
```
@some_variable:     The value;
@another_variable:  You can escape semicolons\; I think;
```

**Boolean** variables look like this:
```
@some_bool;     /* true  */
-@some_bool;    /* false */
```

**Block** variables look like this:
```
@my_box: infobox [United States of America] {
    Declaration:    1776;
    States:         50;
};
```

### Retrieval

Once variables are assigned, they are typically used in
[formatted text](#text-formatting) or [conditionals](#conditionals). You can use
variables anywhere that formatted text is accepted like this:
```
sec {
    This is a paragraph inside a section. I am allow to use [b]bold text[/b],
    as well as [@variables].
}
```

If the variable contains a block, you can display it using `{@var_name}`. This
syntax works anywhere, not just in places where formatted text is accepted
like with the `[@var_name]` syntax. So if you have:
```
@my_box: infobox [United States of America] {
    Declaration:    1776;
    States:         50;
};
```
You would display the infobox later using:
```
{@my_box}
```

### Formatted variables

By the way, you can use text formatting within string variables, including other
embedded variables:
```
@site:      [b]MyWiki[/b];
@name:      John;
@welcome:   Welcome to [@site], [@name].
```

If you don't want that to happen, take a look at
[interpolable variables](#interpolable-variables), the values of which are
formatted upon retrieval rather than at the time of assignment.

### Attributes

Variables can have **attributes**. This helps to organize things:
```
@page.title:    Hello World!;
@page.author:   John Doe;
```

You don't have to worry about whether a variable exists to define attributes on
it. A new variable will be created on the fly if necessary (in the above
example, `@page` does not initially exist but is created automatically).

Some block types support attribute fetching and/or setting:
```
/* define the infobox in a variable so we can access attributes */
@person: infobox [Britney Spears] {
    First name:     Britney;
    Last name:      Spears;
    Age:            35;
};

/* display the infobox */
{@person}

/* access attributes from it elsewhere
   btw this works for all map-based block types */
sec {
    Did you know that [@person.First_name] [@person.Last_name] is
    [@person.Age] years old?
}
```

Some data types may not support attributes at all. Others might only support
certain attributes. For example, [`list{}`](blocks.md#list) only allows
numeric indices.
```
@alphabet: list {
    a;
    b;
    c;
    ... the rest;
};

sec {
    Breaking News: [@alphabet.0] is the first letter of the alphabet,
    and [@alphabet.25] is the last.
}
```

### Conditionals

You can use the **conditional blocks** `if{}`, `elsif{}`, and `else{}` on
variables. Currently all that can be tested is the boolean value of a variable.
Boolean and block variables are always true, and all strings besides zero are
true.
```
if [@page.draft] {
    Note to self: Don't forget to publish this page.
}
else {
    Thanks for checking out my page.
}
```

### Interpolable variables

**Interpolable variables** (with the `%` sigil) allow you to evaluate the
formatting of a string variable at some point after the variable was defined.

Normally the formatting of string variables is evaluated immediately as the
variable is defined.
```
@another_variable: references other variables;
@my_text: This string variable has [b]bold text[/b] and [@another_variable];
/* ok, @my_text now is:
   This string variable has <strong>bold text</strong> and references
   other variables
*/
```

Interpolate variables are different in that their contents
are evaluated as they are accessed rather than as they are defined.
```
@another_variable: references other variables;
%my_text: This string variable has [b]bold text[/b] and [@another_variable];
/* ok, @my_text now is:
   This string variable has [b]bold text[/b] and [@another_variable];
*/
```
Now the variable is defined with the formatting still unevaluated, so
accessing it as `[@my_text]` would display the raw formatting code. Instead,
we use `[%my_text]` to display it which tells the parser to format the
contents of the variable as we retrieve its value.

Whether you defined the variable with `@` or `%` sigil does not concern the
parser. Therefore if you do something like:
```
@my_text: This string variable has [b]bold text[/b];
```
and then try to display it with `[%my_text]`, the variable will be
double-formatted, resulting in ugly escaped HTML tags visible to clients.

### Special variables

`@page` contains information about the current page. Its attributes are set
at the very top of a page source file.

* `@page.title` - Human-readable page title. Utilized internally by the
  Wikifier, so it is required for most purposes. Often used as the `<title>` of
  the page, as well as in the `<h1>` above the first `section{}` block. The
  title can contain [formatted text](#text-formatting), but it may be stripped
  down to plaintext in certain places.
* `@page.created` - UNIX timestamp of the page creation time. This is not used
  in the Wikifier itself, but can be used in frontends for sorting the page list
  by creation date.
* `@page.author` - Name of the page author. This is also optional but may be
  used by frontends to organize pages by author.
* `@page.draft` - [Boolean](#assignment) value which marks the page as a draft.
  This means that it will not be served to unauthenticated users.
* `@page.enable` - Contains [boolean](#assignment) attributes which allow you to
  enable or disable certain features specific to the page.
    * `@page.enable.title` - Whether to display the page title (from
      `@page.title`) as the header of the first `section{}` block. Overrides the
      wiki configuration option
      [page.enable.title](configuration.md#pageenabletitle).
    * `@page.enable.footer` - Whether to omit the closing `<div>` tags such that
      a page footer can be injected. Overrides the wiki configuration option
      [page.enable.footer](configuration.md#pageenablefooter).

`@category` is used to mark the page as belonging to a category. Each
attribute of it is a boolean. If present, the page belongs to that category.
Example:
* `@category.news;`
* `@category.important;`

`@m` is a special variable used in [models](models.md). Its attributes are
mapped to any options provided in the model block.

## Text formatting

Many block types, as well as values in [variable assignment](#assignment), can
contain **formatted text**. Square brackets `[` and `]` are used to delimit text
formatting tokens.

### Basic formatting
* `[b]bold text[/b]` - **bold text**
* `[s]strikethrough text[/s]` - ~~strikethrough text~~
* `[i]italicized text[/i]` - *italicized text*
* `superscript[^]text[/^]` - superscript<sup>text</sup>
* `subscript[v]text[/v]` - subscript<sub>text</sub>
* `[Aquamarine]some colored text by color name[/]`
* `[#ff1337]some colored text by hex code[/]`

### Variables
* `[@some.variable]` - normal variable
* `[%some.variable]` - interpolable variable
* See [Variables](#variables) above

### Links
* `[[ Page name ]]` - internal wiki page link
* `[! Page name !]` - external wiki page link
* `[~ Cat name ~]` - category link
* `[$ http://google.com $]` - external site link
* For any link type, you can change the display text:
  `[$ Google | http://google.com $]`

### References
* `[ref]` - a fake reference. just to make your wiki look credible.
* `[1]` - an actual reference number. a true reference.

### Characters
* `[nl]` - a line break
* `[--]` - an en dash
* `[---]` - an em dash
* `[&copy]` - HTML entities by name
* `[&#34]` - HTML entities by number
