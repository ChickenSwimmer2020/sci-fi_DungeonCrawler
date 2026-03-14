package backend;

import openfl.utils.AssetType;
import flixel.math.FlxRect;

class Alphabet extends FlxTypedSpriteContainer<FlxSprite> {
    //yeah, so FlxText is fucking stupid, and im lazy AF. so instead of FlxText, we're gonna use this.
    //Although FlxText is a backup incase the font png isnt found.
    public var characters:Array<Letter>=[];
    @:isVar public var txt(get, set):String;
    private var internalText:String;
    
    public var fieldWidth:Float=0;
    public var fieldHeight:Float=0;
    public var fontSize:Int=12;

    @:isVar public var alignment(get, set):FlxTextAlign;

    private var letterIndex:Int=0;
    private var curLine:Int=0;
    private var object:FlxSprite=new FlxSprite(0, 0);
    public function new(x:Float,y:Float, fw:Float, text:String, fontSize:Int) {
        super(x, y);
        fieldWidth=fw;
        this.fontSize=fontSize;
        object.makeGraphic(2, 2, 0x0000FF00);
        object.setGraphicSize(fw, fieldHeight);
        object.updateHitbox();
        add(object);
        
        internalText = null; // so set_txt sees it as a change
        txt = text;          // set_txt handles everything
        @:bypassAccessor if(alignment==null) alignment=LEFT; //AFTER the text renders
        recalculateFieldSize(); //call again after making the text so fieldwidth works properly.
        fieldWidth=fw; //try setting again? //*dont touch, it works like this properly. (fieldwidth itself doesnt update its graphic properly lol.)
    }

    public inline function get_txt():String return internalText;
    public function set_txt(value:String):String {
        if(internalText!=value){ //dont even try to update the text if there are no changes, massive overhead if i do.
            for(letter in 0...characters.length){
                remove(characters[letter]);
                characters[letter].destroy();
            }
            characters = []; // also clear the array itself!
            generateVisuals(value);
            internalText=value;
            return value;
        }
        return value;
    }
    public inline function get_alignment():FlxTextAlign return alignment;
    public function set_alignment(value:FlxTextAlign):FlxTextAlign { //force a reconstruction on alignment change.
        letterIndex=0;
        var fieldwidthExactMidpoint:Float=(fieldWidth/2);
        var totalTextEstimatedWidth:Float=(0+(fontSize*internalText.length)); //estimated text width.
        var xPosition:Float=0;
        for(letter in 0...characters.length){
            switch(value) {
                case CENTER:xPosition=fieldwidthExactMidpoint-(totalTextEstimatedWidth/2-(fontSize*letterIndex));
                case RIGHT:xPosition=fieldWidth-(totalTextEstimatedWidth-(fontSize*letterIndex));
                default: xPosition=0+(fontSize*letterIndex); //idk what JUSTIFY is, but if its that or LEFT it defaults.
            }
            characters[letter].x = xPosition;
            letterIndex++;
        }
        return value;
    }

    private function generateVisuals(text:String) {
        trace('generateVisuals called with: $text');
        //trace('fileExists: ${FileSystem.exists('assets/ui/fonts/${Main.curLanguage}.png')}');
        if(#if (hl||windows)FileSystem.exists('assets/ui/fonts/${Main.curLanguage}.png') #else Assets.exists('assets/ui/fonts/${Main.curLanguage}.png', AssetType.IMAGE)#end){
            var wrapWidth:Float = fieldWidth; // save BEFORE resetting
            letterIndex=0;
            fieldHeight=0;
            fieldWidth=0;
            curLine=0;

            for(c in 0...text.length) {
                if(wrapWidth > 0 && letterIndex * fontSize >= wrapWidth && text.charAt(c) != "\n") {
                    curLine++;
                    letterIndex = 0;
                }

                var letter:Letter = new Letter(0+(fontSize*letterIndex),0+(fontSize*curLine),Main.curLanguage,text.charAt(c));
                letter.setGraphicSize(fontSize, fontSize);
                letter.updateHitbox();
                characters.push(letter);
                add(letter);
                if(text.charAt(c)=="\n"){
                    curLine++;
                    letterIndex=0;
                } else {
                    letterIndex++;
                }
            }
        }else{
            trace('MISSING FONT FILE: ${Main.curLanguage}');
            add(new FlxText(0, 0, fieldWidth, text, fontSize, true)); //just as a fallback.
        }
    }
    public function recalculateFieldSize() {
        fieldWidth=(fontSize*characters.length);
        fieldHeight=(fontSize*curLine);
        object.setGraphicSize(fieldWidth, curLine>0?fieldHeight:fontSize); //default to the fontsize if curLine is 0.
        object.updateHitbox();
    }
}

private class Letter extends FlxSprite {
    private static final pointer:Map<String, Map<String, Int>>=[//from string character to int, this is a TERRIBLE way to do it.
        "EN_US"=>[
            //upper case
            "A"=>0,"B"=>1,"C"=>2,"D"=>3,"E"=>4,"F"=>5,"G"=>6,"H"=>7,"I"=>8,"J"=>9,"K"=>10,"L"=>11,
            "M"=>12,"N"=>13,"O"=>14,"P"=>15,"Q"=>16,"R"=>17,"S"=>18,"T"=>19,"U"=>20,"V"=>21,"W"=>22,"X"=>23,"Y"=>24,"Z"=>25,
            //lowercase
            "a"=>26,"b"=>27,"c"=>28,"d"=>29,"e"=>30,"f"=>31,"g"=>32,"h"=>33,"i"=>34,"j"=>35,"k"=>36,"l"=>37,
            "m"=>38,"n"=>39,"o"=>40,"p"=>41,"q"=>42,"r"=>43,"s"=>44,"t"=>45,"u"=>46,"v"=>47,"w"=>48,"x"=>49,"y"=>50,"z"=>51,
            //numbers
            "0"=>52,"1"=>53,"2"=>54,"3"=>55,"4"=>56,"5"=>57,"6"=>58,"7"=>59,"8"=>60,"9"=>61,
            //symbols
            "."=>62,","=>63,"\""=>64,"'"=>65,"?"=>66,"!"=>67,"@"=>68,"_"=>69,"*"=>70,"#"=>71,
            "$"=>72,"%"=>73,"&"=>74,"("=>75,")"=>76,"+"=>77,"-"=>78,"/"=>79,":"=>80,";"=>81,
            "<"=>82,"="=>83,">"=>84,"["=>85,"\\"=>86,"]"=>87,"^"=>88,"`"=>89,"{"=>90,"|"=>91,
            "}"=>92,"~"=>93,"\n"=>94," "=>95
        ],
        "JP"=>[
            "null"=>0,"「"=>1,"未"=>2,"完"=>3,"成"=>4,"の"=>5,"言"=>6,"語"=>7,"」"=>8
        ]
    ];
    private var l:String;
    public function new(x:Float, y:Float, lang:String, letter:String) {
        super(x, y);
        var langu:String=lang;
        if(pointer.get(lang).get(letter) == null) {
            trace('attempted to get symbol $letter from lang $lang, checking other available languages for symbol...');
            var langs:Array<String> = ["EN_US", "JP"];
            var found:Bool = false;
            for(l in 0...langs.length) {
                if(langs[l] == lang) continue; // skip the lang we already know doesn't have it
                if(pointer.get(langs[l]).get(letter) != null) {
                    trace('symbol $letter was found in lang ${langs[l]}!');
                    langu = langs[l];
                    found = true;
                    break; // no need to check further
                }
            }
            if(!found) {
                trace('no language contains symbol $letter, rendering missing graphic');
                letter = "null";
            }
        }
        l=letter;
        frames = FlxTileFrames.fromGraphic(FlxG.bitmap.add('assets/ui/fonts/${Main.curLanguage}.png'), FlxPoint.get(16, 16));
        frame = frames.getByIndex(pointer.get(langu).get(letter));
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        #if(!debug)if(visible&&(l=="\n"||l==" "))visible=false;#end
    }
}