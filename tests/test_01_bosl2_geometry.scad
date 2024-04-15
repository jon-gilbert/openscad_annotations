include <openscad_annotations/bosl2_geometry.scad>

module test_geom() {
    pg = ["prismoid", [15, 15, 15], [15, 15], [0, 0], [0, 0, 1], [0, 0, 0], [0, 0, 0], []];
    geom = Geom(parent_geom=pg);
    assert( obj_is_obj(geom), "Geom() is valid obj");
    assert( geom_type(geom) == "prismoid", "Geom() obj is prismoid");
    assert( geom_axis(geom) == UP,  "axis orientation is UP");
    assert( ParentGeom(geom) == pg,  "ParentGeom() reconstituted geometry matches original");

}
test_geom();

