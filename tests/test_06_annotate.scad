include <openscad_annotations/annotate.scad>


module test_bin2vec() {
    l = [
        [ [ 0, 0, 0, 0, 0, 0, 0, 0 ], [0, 0, 0]    ],
        [ [ 0, 0, 0, 0, 0, 0, 0, 1 ], [-1, 0, 0]   ],
        [ [ 0, 0, 0, 0, 0, 0, 1, 0 ], [0, -1, 0]   ],
        [ [ 0, 0, 0, 0, 0, 0, 1, 1 ], [-1, -1, 0]  ],
        [ [ 0, 0, 0, 0, 0, 1, 0, 0 ], [0, 0, -1]   ],
        [ [ 0, 0, 0, 0, 0, 1, 0, 1 ], [-1, 0, -1]  ],
        [ [ 0, 0, 0, 0, 0, 1, 1, 0 ], [0, -1, -1]  ],
        [ [ 0, 0, 0, 0, 0, 1, 1, 1 ], [-1, -1, -1] ],
        [ [ 0, 0, 0, 0, 1, 0, 0, 0 ], [0, 0, 0]    ],
        [ [ 0, 0, 0, 0, 1, 0, 0, 1 ], [1, 0, 0]    ],
        [ [ 0, 0, 0, 0, 1, 0, 1, 0 ], [0, -1, 0]   ],
        [ [ 0, 0, 0, 0, 1, 0, 1, 1 ], [1, -1, 0]   ],
        [ [ 0, 0, 0, 0, 1, 1, 0, 0 ], [0, 0, -1]   ],
        [ [ 0, 0, 0, 0, 1, 1, 0, 1 ], [1, 0, -1]   ],
        [ [ 0, 0, 0, 0, 1, 1, 1, 0 ], [0, -1, -1]  ],
        [ [ 0, 0, 0, 0, 1, 1, 1, 1 ], [1, -1, -1]  ],
        [ [ 0, 0, 0, 1, 0, 0, 0, 0 ], [0, 0, 0]    ],
        [ [ 0, 0, 0, 1, 0, 0, 0, 1 ], [-1, 0, 0]   ],
        [ [ 0, 0, 0, 1, 0, 0, 1, 0 ], [0, 1, 0]    ],
        [ [ 0, 0, 0, 1, 0, 0, 1, 1 ], [-1, 1, 0]   ],
        [ [ 0, 0, 0, 1, 0, 1, 0, 0 ], [0, 0, -1]   ],
        [ [ 0, 0, 0, 1, 0, 1, 0, 1 ], [-1, 0, -1]  ],
        [ [ 0, 0, 0, 1, 0, 1, 1, 0 ], [0, 1, -1]   ],
        [ [ 0, 0, 0, 1, 0, 1, 1, 1 ], [-1, 1, -1]  ],
        [ [ 0, 0, 0, 1, 0, 0, 0, 0 ], [0, 0, 0]    ],
        [ [ 0, 0, 0, 1, 1, 0, 0, 0 ], [0, 0, 0]    ],
        [ [ 0, 0, 0, 1, 1, 0, 0, 1 ], [1, 0, 0]    ],
        [ [ 0, 0, 0, 1, 1, 0, 1, 0 ], [0, 1, 0]    ],
        [ [ 0, 0, 0, 1, 1, 0, 1, 1 ], [1, 1, 0]    ],
        [ [ 0, 0, 0, 1, 1, 1, 0, 0 ], [0, 0, -1]   ],
        [ [ 0, 0, 0, 1, 1, 1, 0, 1 ], [1, 0, -1]   ],
        [ [ 0, 0, 0, 1, 1, 1, 1, 1 ], [1, 1, -1]   ],
    ];

    for (pair = l)
        assert(pair[1] == bin2vec(pair[0]), str(["bin2vec failure for pair: ", pair]));

}
test_bin2vec();


module test_rec_mat() {
    assert(rec_mat([[1,0,0]], 3) == [3,0,0] );
    assert(rec_mat([[-1,0,1]], 3) == [-3,0,3] );
    assert(rec_mat([[-1,0,1], [0,0,0], [1,1,1]], 3) == [0, 3, 6]);
}
test_rec_mat();


module test_partno2translate() {
    module test_p2t(expected) {
        assert(partno2translate(d=5) == expected, 
            str(["got", partno2translate(d=5), "expected", expected]));
    }

    partno(0) test_p2t([0, 0, 0]);
    partno(1) test_p2t([-5, 0, 0]);
    partno(2) test_p2t([0, 5, 0]);
    partno(3) test_p2t([-5, 5, 0]);
    partno(4) test_p2t([0, 0, 5]);

    partno("a") test_p2t([-5, 0, 0]);
    partno("b") test_p2t([0, -5, 0]);
    partno("c") test_p2t([-5, -5, 0]);
    partno("d") test_p2t([0, 0, 5]);
    partno("e") test_p2t([-5, 0, 5]);

    partno(1) partno(0) partno(1) test_p2t([0, 0, 0]);
    partno(1) partno(1) partno(1) test_p2t([-5, 0, 0]);
}
test_partno2translate();


module test_anno_list_to_block() {
    assert( anno_list_to_block([1, 2, 3])  ==  [1, 2, 3] );
    assert( anno_list_to_block(["a", 2, 3])  ==  ["a", 2, 3] );
    assert( anno_list_to_block(["a", [1, 2], 3])  ==  ["a", "1=2", 3] );
    assert( anno_list_to_block(["a", ["b", 2], 3])  ==  ["a", "b=2", 3] );
}
test_anno_list_to_block();


module test_anno_partno_sequence() {
    a = Annotation(["mech_number", "T", "label", "A", "partno", "1"]);
    assert( anno_partno_sequence(a) == ["T", "A", "1"], 
        str(["T", "A", "1"]) );
    assert( anno_partno_sequence(anno_partno(a, nv="2")) == ["T", "A", "2"], 
        str(["T", "A", "2"]) );

    b = Annotation(["mech_number", "T", "label", "A", "partno", ["1", "2", "a"]]);
    assert( anno_partno_sequence(b) == ["T", "A", "1", "2", "a"], 
        str(["T", "A", "1", "2", "a"]) );
}
test_anno_partno_sequence();


module test_anno_assemble_partno() {
    a = Annotation(["mech_number", "T", "label", "A", "partno", "1"]);
    assert( anno_partno(anno_assemble_partno(a)) == "T-A-1",  "T-A-1" );
    assert( anno_partno(anno_assemble_partno(anno_partno(a, nv="2"))) == "T-A-2" );

    b = Annotation(["mech_number", "T", "label", "A", "partno", ["1", "2", "a"]]);
    assert( anno_partno(anno_assemble_partno(b)) == "T-A-1-2-a" );
}
test_anno_assemble_partno();


module test_bin2vec() {
    assert(bin2vec([0, 0, 0, 0, 0, 0, 0, 0]) == [0, 0, 0]);
    assert(bin2vec([0, 0, 0, 0, 1, 0, 0, 1]) == [1, 0, 0]);
    assert(bin2vec([0, 0, 0, 0, 1, 1, 0, 1]) == [1, 0, -1]);
}
test_bin2vec();


module test_ascii2bin() {
    assert( ascii2bin("a") == [0,1,1,0,0,0,0,1] );
    assert( ascii2bin("ab") == [0,1,1,0,0,0,0,1] );
}
test_ascii2bin();


module test_str2bin() {
    assert( str2bin("abcdefg") == [
        [0,1,1,0,0,0,0,1], [0,1,1,0,0,0,1,0], [0,1,1,0,0,0,1,1], [0,1,1,0,0,1,0,0], [0,1,1,0,0,1,0,1], [0,1,1,0,0,1,1,0], [0,1,1,0,0,1,1,1]
        ]);
}
test_str2bin();



