package backend.parsing;

#if sys
    class File {
        public static inline function saveContent(path:String, content:String):Void return sys.io.File.saveContent(path, content);
        public static inline function getContent(path:String):String return sys.io.File.getContent(path);
        public static inline function getBytes(path:String):Bytes return sys.io.File.getBytes(path);
        public static inline function saveBytes(path:String, bytes:Bytes):Void return sys.io.File.saveBytes(path, bytes);
    }
#end