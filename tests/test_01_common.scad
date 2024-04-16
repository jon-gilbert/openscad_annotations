
include <openscad_annotations/common.scad>

module test_defined() {
    assert( _defined(undef) == false );
    assert( _defined(1)     == true );
    assert( _defined(0)     == true );
    assert( _defined(-1)    == true );
    assert( _defined("a")   == true );
    assert( _defined([])    == false );
    assert( _defined(true)  == true );
    assert( _defined(false) == true );

    x2 = undef;
    assert(false == _defined(x2));

    x1 = "a value";
    assert(true == _defined(x1));

    ar = [1];
    assert(true == _defined(ar));

    as = [];
    assert(false == _defined(as));

}
test_defined();


module test_defined_and_nonzero() {
    // defined_and_nonzero()
    assert( _defined_and_nonzero(undef) == false );
    assert( _defined_and_nonzero(1)     == true );
    assert( _defined_and_nonzero(0)     == false );
    assert( _defined_and_nonzero(-1)    == true );
    assert( _defined_and_nonzero("a")   == true );
    assert( _defined_and_nonzero([])    == false );
    assert( _defined_and_nonzero(true)  == true );
    assert( _defined_and_nonzero(false) == true );
}
test_defined_and_nonzero();


module test_first() {
    assert( _first([undef, "a", undef])  == "a" );
    assert( _first([0, 8])               == 0 );
    assert( _first([undef, 8])           == 8 );
    assert( _first([undef, false, true]) == false);
    assert( _first([undef, [1], true])   == [1] );
    assert( _first([undef, []])          == undef );
    assert( _first([[], 1])              == 1 );
    assert( _first([ [[]], 1])           == [[]] );   // this isn't i think correct

    L1 = [0, undef, 8];
    assert( _first(L1) == 0 );
}
test_first();


module test_first_nonzero() {
    assert( _first_nonzero([0, 0.0, 12, 0]) == 12 );
    assert( _first_nonzero([undef, 0, 12]) == 12 );
    assert( _first_nonzero([undef, 0, -1, 1]) == -1 );
    assert( _first_nonzero(["a", "b"]) == undef );

    L3 = [0, undef, 8];
    assert( _first_nonzero(L3) == 8 );
}
test_first_nonzero();


