unit class Proxee;
use MONKEY-GUTS;

proto method new(|) { * }

multi method new(\coercer where {.HOW ~~ Metamodel::CoercionHOW}) {
    my \from     = coercer.^constraint_type;
    my \to       = coercer.^target_type;
    my $to-name := to.^name;

    my $STORAGE;
    Proxy.new: :FETCH{ $STORAGE }, STORE => -> $, \arg {
        die X::TypeCheck::Binding.new: :got(arg.WHAT), :expected(from), :symbol('<unknown>')
            unless nqp::istype(arg, from); # on 2017.11 is about 13x faster than smartmatch
        $STORAGE := arg."$to-name"()
    }
}
