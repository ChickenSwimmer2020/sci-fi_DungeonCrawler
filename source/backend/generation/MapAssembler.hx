package backend.generation;

typedef MapAssembler = {
    var types:Array<String>;
    var links:Map<String, String>;
    var structures:Map<String, Structure>;
}

typedef Structure = {
    var name:String; // the name of the structure
    var data:String; // the placeholder linking to the gen struct function.
    var type:String; // the placeholder linking to the type of struct from the types.
    var spawnChance:Array<{id:String, chance:Float}>; // the spawn chance of this struct
    var spawnConditions:Array<{condition:String, value:String, isNegative:Bool}>; // the spawn conditions of this struct
    var structProperties:Map<String, String>; // the properties of this struct
}