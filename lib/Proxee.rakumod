use MONKEY-GUTS;

class Proxee::X::CannotProxeeStore is Exception {
    method message {
        'A Proxee cannot use :PROXEE and :STORE at the same time'
    }
}

class Proxee {
    use nqp;

    proto method new(|) { * }
    multi method new(&block) is rw {
        my $v := block;
        nqp::eqaddr($v,Nil)
          ?? self.new
          !! nqp::istype($v, List)
            ?? self.new(|$v.Capture)
            !! self.new(|$v)
    }
    multi method new(\coercer where {.HOW ~~ Metamodel::CoercionHOW}) is rw {
        my \from     = coercer.^constraint_type;
        my \to       = coercer.^target_type;
        my $to-name := to.^name;

        my $STORAGE;
        Proxy.new: :FETCH{ $STORAGE }, STORE => -> $, \v {
            die X::TypeCheck.new: :got(v.WHAT), :expected(from), :operation<Proxee>
                unless nqp::istype(v, from); # on 2017.11 about 13x faster than ~~

            nqp::istype(v, to) ?? ($STORAGE := v)
                               !! ($STORAGE := v."$to-name"());
            $STORAGE
        }
    }
    multi method new(:&PROXEE, :&STORE, :&FETCH) is rw {
        &PROXEE and &STORE and die Proxee::X::CannotProxeeStore.new;

        my &store := &PROXEE ?? { $*PROXEE = PROXEE $_ }
                             !! (&STORE || { $*PROXEE = $_ });
        my &fetch := &FETCH  || { $*PROXEE };

        my $proxee;
        Proxy.new:
          FETCH =>                 { my $*PROXEE := $proxee; fetch   },
          STORE => -> $, \v is raw { my $*PROXEE := $proxee; store v }
    }
}

=begin pod

=head1 NAME

Proxee — A more usable Proxy with bells

=head1 SYNOPSIS

=begin code :lang<raku>

use Proxee;

=end code

General use:

=begin code :lang<raku>

# No self as first arg; simply use a regular block in both code blocks:
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

=end code

Special shared dynamic variable:

=begin code :lang<raku>

# Or just use the special shared variable:
my $stuff2 := Proxee.new: :STORE{ $*PROXEE.push: $_ }, :FETCH{ $*PROXEE.join: ' | ' }
$stuff2 = 42;
$stuff2 = 'meow';
say $stuff2; # OUTPUT: «42 | meow␤»

# Default STORErer
my $cuber := Proxee.new: :FETCH{ $*PROXEE³ };
$cuber = 11;
say $cuber; # OUTPUT: «1331␤»

# Default FETCHer
my $squarer := Proxee.new: :STORE{ $*PROXEE = $_² };
$squarer = 11;
say $squarer; # OUTPUT: «121␤»

# Shortcut to assign to $*PROXEE
my $squarer := Proxee.new: :PROXEE{ $_² };
$squarer = 11;
say $squarer; # OUTPUT: «121␤»

=end code

Coercers (for backward compatibility only):

=begin code :lang<raku>

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

=end code

B<Note>: this option is only provided for backwards compatibility.
Recent version of Rakudo support coercion types out of the box in
variable, parameter and attribute declarations.

=head1 DESCRIPTION

The core L<C<Proxy>|https://docs.raku.org/type/Proxy> type is a bit clunky
to use. This module provides an alternative class C<Proxee> with an improved
interface, and with a few extra features.

=head1 METHODS

=head2 new

=begin code :lang<raku>

multi method new(\coercer where {.HOW ~~ Metamodel::CoercionHOW})
multi method new(:&PROXEE, :&STORE, :&FETCH)
multi method new(&block)

=end code

Creates and returns a new L<C<Proxy>|https://docs.perl6.org/type/Proxy> object
whose C<:STORE> and C<:FETCH> C<Callable>s have been set to behave like
functionality offered by C<Proxee>. Possible arguments are:

=head3 An Improved Proxy

The regular functionality of a L<C<Proxy>|https://docs.perl6.org/type/Proxy>
remains, except the C<Proxy> object is no longer passed to neither C<:FETCH>
nor C<:STORE> callables. C<:FETCH> gets no args; C<:STORE> gets 1 arg, the
value being stored:

=begin code :lang<raku>

my @stuff;
my $stuff := Proxee.new: :STORE{ @stuff.push: $_ }, :FETCH{ @stuff.join: ' | ' }
$stuff = 42;
$stuff = 'meow';
say $stuff; # OUTPUT: «42 | meow␤»

=end code

In addition, automated storage is available. B<Assign> (do not bind, or
you'll break it) to C<$*PROXEE> variable to store the value in the automated
storage and read from it to retrieve that value:

=begin code :lang<raku>

my $stuff2 := Proxee.new:
  :STORE{ $*PROXEE.push: $_ },
  :FETCH{ $*PROXEE.join: ' | ' }
$stuff2 = 42;
$stuff2 = 'meow';
say $stuff2; # OUTPUT: «42 | meow␤»

=end code

The C<:STORE> argument is optional and B<defaults to> C<{ $*PROXEE = $_ }>.
The C<:FETCH> argument is optional and B<defaults to> C<{ $*PROXEE }>.
The C<:PROXEE> argument is like C<:STORE>, except it also assigns itsi
return value to C<$*PROXEE>:

=begin code :lang<raku>

my $squarer := Proxee.new: :PROXEE{ $_² };
$squarer = 11;
say $squarer; # OUTPUT: «121␤»

=end code

Attempting to use both C<:PROXEE> and C<:STORE> arguments at the same time
will throw C<Proxee::X::CannotProxeeStore> exception.

=head3 A Callable

You can also pass a single codeblock as an argument. It will be evaluated
and its return value will be used as arguments to C<Proxee.new> (after slight
massaging to make C<Pair>s in a C<List> be passed as named args).

This feature exists to make it slightly simpler to use closures with a Proxy:

=begin code :lang<raku>

my $stuff2 := Proxee.new: {
    my @stuff;
    :STORE{ @stuff.push: $_    },
    :FETCH{ @stuff.join: ' | ' }
}
$stuff2 = 42;
$stuff2 = 'meow';
say $stuff2; # OUTPUT: «42 | meow␤»

=end code

The above is equivalent to:

=begin code :lang<raku>

my $stuff2 := do {
    my @stuff;
    Proxee.new: :STORE{ @stuff.push: $_    },
                :FETCH{ @stuff.join: ' | ' }
}
$stuff2 = 42;
$stuff2 = 'meow';
say $stuff2; # OUTPUT: «42 | meow␤»

=end code

Watch out you don't accidentally pass a block that would be interpreted
as a C<Hash>:

=begin code :lang<raku>

Proxy.new:    { :STORE{;}, :FETCH{;} } # WRONG; It's a Hash
Proxy.new: -> { :STORE{;}, :FETCH{;} } # RIGHT; It's a Block

=end code

=head3 Coercer

Pass a coercer as a positional argument to create a coercing proxy that
coerces stored values to specified type:

=begin code :lang<raku>

my  $Cool-to-Int := Proxee.new: Int(Cool);
$Cool-to-Int = ' 42.70 ';
say $Cool-to-Int; # OUTPUT: «42␤»

$Cool-to-Int = Date.today
# OUTPUT: «Type check failed in Proxee; expected Cool but got Date (Date)␤»

=end code

B<Note>: none of C<:&PROXEE>, C<:&STORE>, C<:&FETCH> can be used together
with the coercer argument.

B<Note>: this option is only provided for backwards compatibility.
Recent version of Rakudo support coercion types out of the box in
variable, parameter and attribute declarations.

=begin code :lang<raku>

my Int(Cool) $Cool-to-Int = ' 42.70';
say $Cool-to-Int; # OUTPUT: «42␤»

$Cool-to-Int = Date.today
# OUTPUT: «Type check failed in Proxee; expected Cool but got Date (Date)␤»

=end code

=head1 AUTHOR

Zoffix Znet

=head1 COPYRIGHT AND LICENSE

Copyright 2017 - 2018 Zoffix Znet

Copyright 2019 - 2022 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
