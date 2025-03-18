include <openscad_annotations/annotate.scad>


module test_bin2vec() {
    assert(bin2vec([0, 0, 0, 0, 0, 0, 0, 0]) == [0, 0, 0]);
    assert(bin2vec([0, 0, 0, 0, 1, 0, 0, 1]) == [1, 0, 0]);
    assert(bin2vec([0, 0, 0, 0, 1, 1, 0, 1]) == [1, 0, -1]);
}
test_bin2vec();


module test_ascii2bin() {
    assert( ascii2bin("a") == [0,1,1,0,0,0,0,1] );
    assert( ascii2bin("ab") == [0,1,1,0,0,0,0,1] );
    assert( ascii2bin("0") == [0,0,1,1,0,0,0,0] );
    assert( ascii2bin(0) == [0,0,1,1,0,0,0,0] );
}
test_ascii2bin();


module test_str2bin() {
    assert( str2bin("abcdefg") == [
        [0,1,1,0,0,0,0,1], [0,1,1,0,0,0,1,0], [0,1,1,0,0,0,1,1], [0,1,1,0,0,1,0,0], [0,1,1,0,0,1,0,1], [0,1,1,0,0,1,1,0], [0,1,1,0,0,1,1,1]
        ]);
}
test_str2bin();


module test_bin2vec2() {
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
test_bin2vec2();


module test_anno_partno_list() {
    module t_anno_partno_list(expected) {
        tv = anno_partno_list();
        assert(tv == expected,
            str(["got", tv, ", expected", expected]));
    }
    partno(0)               t_anno_partno_list([0]);
    partno(1)   partno(1)   t_anno_partno_list([1, 1]);
    partno("a")             t_anno_partno_list(["a"]);
    partno("a") partno("b") t_anno_partno_list(["a", "b"]);
    partno(1)   partno("b") t_anno_partno_list([1, "b"]);
    partno("a") partno(1)   t_anno_partno_list(["a", 1]);
}
test_anno_partno_list();


module test_partno_retr() {
    module t_partno(expected) {
        tv = partno();
        assert(tv == expected,
            str(["got", tv, ", expected", expected]));
    }
    partno(0)               t_partno("0");
    partno(1)   partno(1)   t_partno("1-1");
    partno("a")             t_partno("a");
    partno("a") partno("b") t_partno("a-b");
    partno(1)   partno("b") t_partno("1-b");
    partno("a") partno(1)   t_partno("a-1");
}
test_partno_retr();


module test_anno_partno_translate() {
    module test_p2t(expected) {
        tv = anno_partno_translate(d=5);
        assert(tv == expected, 
            str(["got", tv, ", expected", expected]));
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

    partno(1) partno(0) partno(1) test_p2t([-10, 0, 0]);
    partno(1) partno(1) partno(1) test_p2t([-15, 0, 0]);
}
test_anno_partno_translate();


module test_anno_list_to_block() {
    assert( anno_list_to_block([1, 2, 3])  ==  [1, 2, 3] );
    assert( anno_list_to_block(["a", 2, 3])  ==  ["a", 2, 3] );
    assert( anno_list_to_block(["a", [1, 2], 3])  ==  ["a", "1=2", 3] );
    assert( anno_list_to_block(["a", ["b", 2], 3])  ==  ["a", "b=2", 3] );
}
test_anno_list_to_block();



