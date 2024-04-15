include <openscad_annotations/mechanical.scad> 

module test_mech () {
    m = mech("rotational", direction="ccw", limit=100);
    assert(mech_type(m) == "rotational");
    assert(mech_direction(m) == ["ccw"]);
    assert(mech_limit(m) == 100);
    // defaults
    assert(mech_geom(m) == []);
    assert(mech_pivot(m) == CENTER);
    assert(mech_pivot_radius(m) == undef);
}
test_mech();



module test_mech_directions_by_type() {
    assert( mech_direction( mech("rotational", direction=undef ) )             == ["cw", "ccw"] );
    assert( mech_direction( mech("rotational", direction=[] ) )                == ["cw", "ccw"] );
    assert( mech_direction( mech("rotational", direction="cw"  ) )             == ["cw"] );
    assert( mech_direction( mech("rotational", direction="ccw" ) )             == ["ccw"] );
    assert( mech_direction( mech("rotational", direction=["cw"] ) )            == ["cw"] );
    assert( mech_direction( mech("rotational", direction=["cw", "ccw"] ) )     == ["cw", "ccw"] );
    assert( mech_direction( mech("rotational", direction=["ccw", "cw"] ) )     == ["ccw", "cw"] );


    assert( mech_direction( mech("oscillatory", direction=undef ) )            == ["cw", "ccw"] );
    assert( mech_direction( mech("oscillatory", direction=[] ) )               == ["cw", "ccw"] );
    assert( mech_direction( mech("oscillatory", direction="cw"  ) )            == ["cw", "ccw"] );
    assert( mech_direction( mech("oscillatory", direction=["cw"] ) )           == ["cw", "ccw"] );
    assert( mech_direction( mech("oscillatory", direction=["ccw"] ) )          == ["cw", "ccw"] );
    assert( mech_direction( mech("oscillatory", direction=["cw", "ccw"] ) )    == ["cw", "ccw"] );


    assert( mech_direction( mech("lateral", direction=undef ) )         == [UP] );
    assert( mech_direction( mech("lateral", direction=UP ) )            == [UP] );
    assert( mech_direction( mech("lateral", direction=[UP] ) )          == [UP] );
    assert( mech_direction( mech("lateral", direction=[UP, DOWN] ) )    == [UP, DOWN] );
    assert( mech_direction( mech("lateral", direction=[] ) )            == [UP] );
    assert( mech_direction( mech("lateral", direction=[UP+LEFT] ) )          == [UP+LEFT] );


    assert( mech_direction( mech("reciprocal", direction=undef ) )      == [UP, DOWN] );
    assert( mech_direction( mech("reciprocal", direction=[UP, DOWN] ) ) == [UP, DOWN] );
    assert( mech_direction( mech("reciprocal", direction=[UP] ) )       == [UP, DOWN] );
    assert( mech_direction( mech("reciprocal", direction=[DOWN] ) )     == [DOWN, UP] );
    assert( mech_direction( mech("reciprocal", direction=[LEFT] ) )     == [LEFT, RIGHT] );
    assert( approx( mech_direction( mech("reciprocal", direction=LEFT) ), [LEFT, RIGHT]) );
    assert( approx( mech_direction( mech("reciprocal", direction=LEFT+DOWN) ), [LEFT+DOWN, RIGHT+UP]) );
}
test_mech_directions_by_type();

/*
module test_mech_compare() {
    // TODO: this requires far more comparison testing than I'm willing to commit to today. 
    // 
    LOG_LEVEL=LOG_ERROR;
    // lateral to lateral
    log_error_unless(mech_compare( mech("lateral", direction=[UP]), mech("lateral", direction=[UP])), "lateral/lateral: dir: up/up; axis: up/up; limit:undef/undef -- 1");
    log_error_if(mech_compare( mech("lateral", direction=[UP]), mech("lateral", direction=[DOWN])), "lateral/lateral: dir: up/down; axis: up/up; limit:undef/undef -- 2");
    log_error_unless(mech_compare( mech("lateral", direction=[DOWN]), mech("lateral", direction=[DOWN])), "lateral/lateral: dir: down/down; axis: up/up; limit:undef/undef -- 3");
    log_error_if(mech_compare( mech("lateral", direction=[DOWN]), mech("lateral", direction=[UP])), "lateral/lateral: dir: down/up; axis: up/up; limit:undef/undef -- 4");
    // lateral to reciprocal:
    log_error_unless(mech_compare( mech("lateral", direction=[UP]), mech("reciprocal")), "lateral/reciprocal: dir: up/both; axis: up/up; limit:undef/undef -- 5");
    log_error_unless(mech_compare( mech("lateral", direction=[DOWN]), mech("reciprocal")), "lateral/reciprocal: dir: down/both; axis: up/up; limit:undef/undef -- 6");
    log_error_unless(mech_compare( mech("lateral", direction=[UP]), mech("reciprocal", direction=[UP])), "lateral/reciprocal: dir: up/up; axis: up/up; limit:undef/undef -- 7");
    log_error_unless(mech_compare( mech("lateral", direction=[DOWN]), mech("reciprocal", direction=[DOWN])), "lateral/reciprocal: dir: down/down; axis: up/up; limit:undef/undef -- 8");
    log_error_unless(mech_compare( mech("lateral", direction=[UP]), mech("reciprocal", direction=[DOWN])), "lateral/reciprocal: dir: up/down; axis: up/up; limit:undef/undef -- 9");
    log_error_unless(mech_compare( mech("lateral", direction=[DOWN]), mech("reciprocal", direction=[UP])), "lateral/reciprocal: dir: down/up; axis: up/up; limit:undef/undef -- 10");
    // lateral to rotational
    log_error_if(mech_compare( mech("lateral", direction=[UP]), mech("rotational", direction=["cw", "ccw"])), "lateral/rotational: dir: up/both; axis: up/up; limit:undef/undef  -- 11");
    log_error_if(mech_compare( mech("lateral", direction=[DOWN]), mech("rotational", direction=["cw", "ccw"])), "lateral/rotational: dir: down/both; axis: up/up; limit:undef/undef  -- 12");
    // lateral to oscillatory
    log_error_if(mech_compare( mech("lateral", direction=[UP]), mech("oscillatory", direction=[UP, DOWN])), "lateral/oscillatory: dir: up/both; axis: up/up; limit:undef/undef  -- 13");
    log_error_if(mech_compare( mech("lateral", direction=[DOWN]), mech("oscillatory", direction=[UP, DOWN])), "lateral/oscillatory: dir: down/both; axis: up/up; limit:undef/undef -- 14");
    // reciprocal to reciprocal:
    log_error_unless(mech_compare( mech("reciprocal", direction=[UP, DOWN]), mech("reciprocal", direction=[UP, DOWN])), "reciprocal/reciprocal: dir: both/both; axis: up/up; limit:undef/undef  -- 15");
    log_error_unless(mech_compare( mech("reciprocal", direction=[DOWN]), mech("reciprocal", direction=[DOWN])), "reciprocal/reciprocal: dir: down/down; axis: up/up; limit:undef/undef  -- 16");
    log_error_unless(mech_compare( mech("reciprocal", direction=[DOWN]), mech("reciprocal", direction=[DOWN])), "reciprocal/reciprocal: dir: down/down; axis: up/down; limit:undef/undef  -- 17");
    // reciprocal to lateral:
    log_error_unless(mech_compare( mech("reciprocal", direction=[UP, DOWN]), mech("lateral", direction=[DOWN])), "reciprocal/lateral: dir: both/down; axis: up/up; limit:undef/undef  -- 18");
    log_error_unless(mech_compare( mech("reciprocal", direction=[UP, DOWN]), mech("lateral", direction=[UP])), "reciprocal/lateral: dir: both/up; axis: up/up; limit:undef/undef  -- 19");
    // reciprocal to rotational
    log_error_if(mech_compare( mech("reciprocal", direction=[UP]), mech("rotational", direction=[UP, DOWN])), "reciprocal/rotational: dir: up/both; axis: up/up; limit:undef/undef  -- 20");
    log_error_if(mech_compare( mech("reciprocal", direction=[DOWN]), mech("rotational", direction=[UP, DOWN])), "reciprocal/rotational: dir: down/both; axis: up/up; limit:undef/undef  -- 21");
    // reciprocal to oscillatory
    log_error_if(mech_compare( mech("reciprocal", direction=[UP]), mech("oscillatory", direction=[UP, DOWN])), "reciprocal/oscillatory: dir: up/both; axis: up/up; limit:undef/undef  -- 22");
    log_error_if(mech_compare( mech("reciprocal", direction=[DOWN]), mech("oscillatory", direction=[UP, DOWN])), "reciprocal/oscillatory: dir: down/both; axis: up/up; limit:undef/undef  -- 23");
    // oscillatory to reciprocal:
    log_error_if(mech_compare( mech("oscillatory", direction=["cw", "ccw"]), mech("reciprocal", direction=[UP, DOWN])), "oscillatory/reciprocal: dir: both/both; axis: up/up; limit:undef/undef  -- 24");
    log_error_if(mech_compare( mech("oscillatory", direction=[DOWN]), mech("reciprocal")), "oscillatory/reciprocal: dir: down/both; axis: up/up; limit:undef/undef  -- 25");
    // oscillatory to lateral:
    log_error_if(mech_compare( mech("oscillatory", direction=["cw", "ccw"]), mech("lateral", direction=[DOWN])), "oscillatory/lateral: dir: both/down; axis: up/up; limit:undef/undef  -- 26");
    log_error_if(mech_compare( mech("oscillatory", direction=["cw", "ccw"]), mech("lateral", direction=[UP])), "oscillatory/lateral: dir: both/down; axis: up/up; limit:undef/undef  -- 27");
    // oscillatory to rotational
    log_error_unless(mech_compare( mech("oscillatory", direction=["cw", "ccw"]), mech("rotational", direction=["cw", "ccw"])), "oscillatory/rotational: dir: both/both; axis: up/up; limit:undef/undef  -- 28");
    log_error_unless(mech_compare( mech("oscillatory", direction=["cw", "ccw"]), mech("rotational", direction=["cw"])), "oscillatory/rotational: dir: both/cw; axis: up/up; limit:undef/undef  -- 29");
    log_error_unless(mech_compare( mech("oscillatory", direction=["cw", "ccw"]), mech("rotational", direction=["ccw"])), "oscillatory/rotational: dir: both/ccw; axis: up/up; limit:undef/undef  -- 30");
    // oscillatory to oscillatory
    log_error_unless(mech_compare( mech("oscillatory", direction=[UP]), mech("oscillatory", direction=["cw", "ccw"])), "oscillatory/oscillatory: dir: up/both; axis: up/up; limit:undef/undef  -- 41");
    log_error_unless(mech_compare( mech("oscillatory", direction=[DOWN]), mech("oscillatory", direction=["cw", "ccw"])), "oscillatory/oscillatory: dir: down/both; axis: up/up; limit:undef/undef  -- 42");
    // rotational to reciprocal:
    log_error_if(mech_compare( mech("rotational", direction=["cw", "ccw"]), mech("reciprocal", direction=[UP, DOWN])), "rotational/reciprocal: dir: both/both; axis: up/up; limit:undef/undef  -- 43");
    log_error_if(mech_compare( mech("rotational", direction=["cw"]), mech("reciprocal", direction=[UP, DOWN])), "rotational/reciprocal: dir: cw/both; axis: up/up; limit:undef/undef  -- 44");
    log_error_if(mech_compare( mech("rotational", direction=["ccw"]), mech("reciprocal", direction=[UP, DOWN])), "rotational/reciprocal: dir: ccw/both; axis: up/up; limit:undef/undef  -- 45");
    // rotational to lateral:
    log_error_if(mech_compare( mech("rotational", direction=["cw", "ccw"]), mech("lateral", direction=[DOWN])), "rotational/lateral: dir: both/down; axis: up/up; limit:undef/undef  -- 46");
    log_error_if(mech_compare( mech("rotational", direction=["cw"]), mech("lateral", direction=[DOWN])), "rotational/lateral: dir: cw/down; axis: up/up; limit:undef/undef  -- 47");
    log_error_if(mech_compare( mech("rotational", direction=["ccw"]), mech("lateral", direction=[DOWN])), "rotational/lateral: dir: ccw/down; axis: up/up; limit:undef/undef  -- 48");
    // rotational to rotational
    log_error_unless(mech_compare( mech("rotational", direction=["cw", "ccw"]), mech("rotational", direction=["cw", "ccw"])), "rotational/rotational: dir: both/both; axis: up/up; limit:undef/undef  -- 49");
    log_error_unless(mech_compare( mech("rotational", direction=["cw"]), mech("rotational", direction=["cw", "ccw"])), "rotational/rotational: dir: cw/both; axis: up/up; limit:undef/undef  -- 50");
    log_error_unless(mech_compare( mech("rotational", direction=["ccw"]), mech("rotational", direction=["cw", "ccw"])), "rotational/rotational: dir: ccw/both; axis: up/up; limit:undef/undef  -- 51");
    log_error_unless(mech_compare( mech("rotational", direction=["cw", "ccw"]), mech("rotational", direction=["cw"])), "rotational/rotational: dir: both/cw; axis: up/up; limit:undef/undef  -- 52");
    log_error_unless(mech_compare( mech("rotational", direction=["cw", "ccw"]), mech("rotational", direction=["ccw"])), "rotational/rotational: dir: both/ccw; axis: up/up; limit:undef/undef  -- 53");
    log_error_unless(mech_compare( mech("rotational", direction=["cw"]), mech("rotational", direction=["cw"])), "rotational/rotational: dir: cw/cw; axis: up/up; limit:undef/undef  -- 54");
    log_error_unless(mech_compare( mech("rotational", direction=["ccw"]), mech("rotational", direction=["ccw"])), "rotational/rotational: dir: ccw/ccw; axis: up/up; limit:undef/undef  -- 55");
    log_error_if(mech_compare( mech("rotational", direction=["cw"]), mech("rotational", direction=["ccw"])), "rotational/rotational: dir: cw/ccw; axis: up/up; limit:undef/undef  -- 56");
    log_error_if(mech_compare( mech("rotational", direction=["ccw"]), mech("rotational", direction=["cw"])), "rotational/rotational: dir: ccw/cw; axis: up/up; limit:undef/undef  -- 57");
    // rotational to oscillatory
    log_error_unless(mech_compare( mech("rotational", direction=["cw", "ccw"]), mech("oscillatory", direction=["cw", "ccw"])), "rotational/oscillatory: dir: both/both; axis: up/up; limit:undef/undef  -- 58");
    log_error_unless(mech_compare( mech("rotational", direction=["cw"]), mech("oscillatory", direction=["cw", "ccw"])), "rotational/oscillatory: dir: cw/both; axis: up/up; limit:undef/undef  -- 59");
    log_error_unless(mech_compare( mech("rotational", direction=["ccw"]), mech("oscillatory", direction=["cw", "ccw"])), "rotational/oscillatory: dir: ccw/both; axis: up/up; limit:undef/undef  -- 60");
    //
    // mirrored reciprocal approx:
    log_error_unless(mech_compare( mech("reciprocal", direction=[UP]), mech("reciprocal", direction=[DOWN])), "reciprocal/reciprocal: dir: UP/DOWN; axis: up/up; limit:undef/undef  -- 61");
    log_error_unless(mech_compare( mech("reciprocal", direction=[UP+RIGHT]), mech("reciprocal", direction=[DOWN+LEFT])), "reciprocal/reciprocal: dir: UP+RIGHT/DOWN+LEFT; axis: up/up; limit:undef/undef  -- 62");
    //
    // unequal axis
    log_error_unless(mech_compare( mech("lateral", direction=[UP], axis=UP), mech("lateral", direction=[UP], axis=UP)), "lateral/lateral: dir: up/up; axis: up/up; limit:undef/undef -- 63");
    log_error_unless(mech_compare( mech("lateral", direction=[UP], axis=UP), mech("lateral", direction=[UP], axis=DOWN)), "lateral/lateral: dir: up/both; axis: up/up; limit:undef/undef -- 64");
    log_error_unless(mech_compare( mech("lateral", direction=[UP], axis=UP+RIGHT), mech("lateral", direction=[UP], axis=DOWN+LEFT)), "lateral/lateral: dir: up/up; axis: up+right/down+left; limit:undef/undef -- 65");
    log_error_unless(mech_compare( mech("reciprocal", direction=[UP], axis=UP+RIGHT), mech("reciprocal", direction=[UP], axis=DOWN+LEFT)), "reciprocal/reciprocal: dir: up/up; axis: up+right/down+left; limit:undef/undef -- 66");
    log_error_if(mech_compare( mech("reciprocal", direction=[UP], axis=UP+RIGHT), mech("reciprocal", direction=[UP], axis=DOWN+RIGHT)), "reciprocal/reciprocal: dir: up/up; axis: up+right/down+right; limit:undef/undef -- 67");
    
}
test_mech_compare();

*/
