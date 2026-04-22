package backend.parsing;

#if sys
    class File {
        public static inline function saveContent(path:String, content:String):Void return sys.io.File.saveContent(path, content);
        public static inline function getContent(path:String):String return sys.io.File.getContent(path);
        public static function getPrecacheableAssets(root:Null<String>):Array<String> {
            var returnArray:Array<String>=[];

            for(path in Paths.paths) {
                if(FileSystem.exists(path)) {
                    for(file in FileSystem.readDirectory(path)) {
                        if(file.isDataFile()){
                            returnArray.push(file);
                        }else{
                            returnArray.combine(checkRecursive('$path/$file'));
                        }
                    }
                }
            }
            
            return returnArray;
        }



        //this is based on Json.hx's recursion lookup.
        public static function checkRecursive(root:Null<String>):Array<String> {
            var returnArray:Array<String>=[];
            var current:String=root??"assets";
            for(file in FileSystem.readDirectory(current)) {
                if(current==null) return null;
                if(FileSystem.isDirectory(file)){
                    returnArray.combine(checkRecursive('$current/$file'));//probably should do this i thing.
                }
                else{
                    trace(file);
                    returnArray.push(file);
                }
            }
            return returnArray;
        }
    }
#end