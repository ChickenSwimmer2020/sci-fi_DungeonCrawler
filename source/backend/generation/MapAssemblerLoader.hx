package backend.generation;

import backend.generation.MapAssembler;
import backend.generation.MapAssembler.Structure;

class MapAssemblerLoader {
    public static function loadAssambler(data:String):MapAssembler
    {
        // clean the data
        inline function cleanData(data:String):String
        {
            // remove multi-line comments (--/ comment here /--)
            var blockRegex = ~/--\/[\s\S]*?\/--/g;
            data = blockRegex.replace(data, '');
        
            // remove single-line comments (-- comment here)
            var lineRegex = ~/--.*$/gm;
            data = lineRegex.replace(data, '');
        
            // remove extra empty lines
            var emptyLines = ~/^\s*\n/gm;
            data = emptyLines.replace(data, '');
        
            // remove indentation from each line
            var indentRegex = ~/^\s+/gm;
            data = indentRegex.replace(data, '');
        
            return data;
        }

        data = cleanData(data);




        // initialize the assembler.
        var assembler:MapAssembler = {
            types: [],
            links: new Map<String, String>(),
            structures: new Map<String, Structure>()
        }


        // process the linkGenerators block.

        // first, get the actual data in the block.
        var start = data.indexOf('linkGenerators');
        var end = data.indexOf('endLinkGenerators');
        var linkGenerators = data.substring(start + 14, end).trim();

        // now split the data into lines,
        var linkData = linkGenerators.split('\n');

        // then split each line into key and value and save them.
        for (link in linkData) {
            var parts = link.split(' = ');
            assembler.links.set(parts[0], parts[1].trim());
        }



        // process the defTypes block.

        // first, again, get the actual data in the block.
        var start1 = data.indexOf('defTypes');
        var end1 = data.indexOf('endTypes');
        var defTypes = data.substring(start1 + 8, end1).trim();

        // now split the data into lines.
        var defData = defTypes.split('\n');

        // then trim each line and save them.
        for (def in defData)
            assembler.types.push(def.trim());



        // time for the most complicated block: the defStructures block.

        // first, once again, get the actual data in the block.
        var start2 = data.indexOf('defStructs');
        var end2 = data.indexOf('endStructs');
        var defStructs = data.substring(start2 + 10, end2).trim();

        // now split the data into each newStruct.
        var defData = defStructs.split('newStruct');

        for (def in defData) {
            if (def.trim() == '') continue;

            var structure:Structure = {
                name: '',
                data: '',
                type: '',
                spawnChance: [],
                spawnConditions: [],
                structProperties: new Map<String, String>()
            };

            // now split the data into each line and process it.
            var lines = def.split('\n');
            for (lineID in 0...lines.length) {
                var line = lines[lineID];
                // the first line is the name of this struct.
                if (lineID == 0) {
                    structure.name = line.trim();
                    continue;
                }

                // get the struct data
                if (line.startsWith('data')) {
                     // turn "data = something" into "something"
                    structure.data = line.replace('data = ', '').replace('data=', '').trim();
                    continue;
                }

                // get the struct type
                if (line.startsWith('type')) {
                    // turn "type = something" into "something"
                    structure.type = line.replace('type = ', '').replace('type=', '').trim();
                    continue;
                }

                // get the spawn chance
                if (line.startsWith('defSpawnChance')) {
                    // get the line id of the end of the spawn chance block
                    var endLineID = -1;
                    for (lineID in 0...lines.length) {
                        if (lines[lineID].startsWith('endSpawnChance')) {
                            endLineID = lineID;
                            break;
                        }
                    }
                    
                    if (endLineID != -1) {
                        // get the spawn chance data
                        var spawnChanceData = lines.slice(lineID + 1, endLineID);
                        // now process and save the spawn chance data
                        for (spawnChance in spawnChanceData) {
                            var parts = spawnChance.split(' ');
                            structure.spawnChance.push({id: parts[1], chance: Std.parseFloat(parts[2])});
                        }
                    }
                }

                if (line.startsWith('defSpawnCondition')) {
                    // get the line id of the end of the spawn condition block
                    var endLineID = -1;
                    for (lineID in 0...lines.length) {
                        if (lines[lineID].startsWith('endSpawnCondition')) {
                            endLineID = lineID;
                            break;
                        }
                    }
                    
                    if (endLineID != -1) {
                        // get the spawn condition data
                        var spawnConditionData = lines.slice(lineID + 1, endLineID);
                        // now process and save the spawn condition data
                        for (spawnCondition in spawnConditionData) {
                            var parts = spawnCondition.split(' ');
                            var r = ~/"(.*?)"/;
                            // check if the condition is a runCheck or not
                            if (parts[0].startsWith('runCheck')) {
                                structure.spawnConditions.push({condition: 'runCheck', value: r.match(parts[0]) ? r.matched(1).trim() : '', isNegative: parts[0].startsWith('!')});
                            } else
                                structure.spawnConditions.push({condition: parts[1], value: parts[2].trim(), isNegative: parts[0].startsWith('!')});
                        }
                    }
                }

                if (line.startsWith('defStructProps')) {
                    // get the line id of the end of the struct props block
                    var endLineID = -1;
                    for (lineID in 0...lines.length) {
                        if (lines[lineID].startsWith('endStructProps')) {
                            endLineID = lineID;
                            break;
                        }
                    }
                    
                    if (endLineID != -1) {
                        // get the struct properties
                        var structureProperties = lines.slice(lineID + 1, endLineID);
                        // now process and save the struct properties
                        for (structureProperty in structureProperties) {
                            var parts = structureProperty.split(' ');
                            var r = ~/\((.*?)\)/;
                            structure.structProperties.set(parts[1].substring(0, parts[1].indexOf('(')), r.match(parts[1]) ? r.matched(1) : '');
                        }
                    }
                }
            }

            assembler.structures.set(structure.name, structure);
        }

        return assembler;
    }
}