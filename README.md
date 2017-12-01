# NAME

`Proxee` — A more usable [`Proxy`](https://docs.perl6.org/type/Proxy) with bells

# SYNOPSIS

```perl6
    use Proxee;
```

Coercers:

```perl6
    # Coercer types on variables:
    my $integral := Proxee.new: Int();
    $integral = ' 42.1e0 ';
    say $integral; # OUTPUT: «42␤»

    # Coercer types on attributes:
    class Foo {
        has $.foo is rw;
        submethod TWEAK (:$foo) { ($!foo := Proxee.new: Int()) = $foo }
    }
    my $o = Foo.new: :foo('42.1e0');
    say $o.foo;       # OUTPUT: «42␤»
    $o.foo = 12.42;
    say $o.foo;       # OUTPUT: «12␤»
```

General use:

```perl6
    # No `self` as first arg; simply use a regular block in both code blocks:
    my @stuff;
    my $stuff := Proxee.new: :STORE{ @stuff.push: $_ }, :FETCH{ @stuff.join: ' | ' }
    $stuff = 42;
    $stuff = 'meow';
    say $stuff; # OUTPUT: «42 | meow␤»

    # Single block as arg; keep all related bits in one place
    my $stuff2 := Proxee.new: {
        my @stuff;
        :STORE{ @stuff.push: $_    },
        :FETCH{ @stuff.join: ' | ' }
    }
    $stuff2 = 42;
    $stuff2 = 'meow';
    say $stuff2; # OUTPUT: «42 | meow␤»
```

Special shared dynvar:

```perl6
    # Or just use the special shared variable:
    my $stuff2 := Proxee.new: :STORE{ $*PROXEE.push: $_ }, :FETCH{ $*PROXEE.join: ' | ' }
    $stuff2 = 42;
    $stuff2 = 'meow';
    say $stuff2; # OUTPUT: «42 | meow␤»

    # Default FETCHer
    my $squarer := Proxee.new: :STORE{ $*PROXEE = $_² },
    $squarer = 11;
    say $squarer; # OUTPUT: «121␤»

    # Default STORErer
    my $cuber := Proxee.new: :FETCH{ $*PROXEE³ },
    $cuber = 11;
    say $squarer; # OUTPUT: «1331␤»
```

# DESCRIPTION

The core [`Proxy`](https://docs.perl6.org/type/Proxy) type is a bit clunky to use. This module
provides an alternative, improved interface, with a few extra features.

----

#### REPOSITORY

Fork this module on GitHub:
https://github.com/zoffixznet/perl6-Proxee

#### BUGS

To report bugs or request features, please use
https://github.com/zoffixznet/perl6-Proxee/issues

#### AUTHOR

Zoffix Znet (http://perl6.party/)

#### LICENSE

You can use and distribute this module under the terms of the
The Artistic License 2.0. See the `LICENSE` file included in this
distribution for complete details.

Syntax highlighting CSS code is based on GitHub Light v0.4.1,
Copyright (c) 2012 - 2017 GitHub, Inc. Licensed under MIT
https://github.com/primer/github-syntax-theme-generator/blob/master/LICENSE

The `META6.json` file of this distribution may be distributed and modified
without restrictions or attribution.
