public function generate():Schematic {
    // This is how you'll load one from file.
    var schematic = SchematicLoader.load('schematics/testSchem.schem');
    return schematic;
}