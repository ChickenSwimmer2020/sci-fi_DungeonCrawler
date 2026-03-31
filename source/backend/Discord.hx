package backend;

#if sys //this is a SYS feature only, because it uses sockets n shit.
    import sys.thread.Thread;
    import sys.thread.Mutex;

    class Discord {
        var pipe:sys.io.FileOutput;
        var pipeIn:sys.io.FileInput;
        var thread:Thread;
        var mutex:Mutex = new Mutex();
        var connected:Bool = false;
        var pendingSend:Array<{opcode:Int, payload:String}> = [];

        public function new(clientId:String) {connect(clientId);};

        //TODO: fix crash when trying to close while discord is attempting to connect.
        private function connect(clientId:String):Void {
            thread = Thread.create(() -> {
                try {
                    var path = "\\\\.\\pipe\\discord-ipc-0";
                    pipe = sys.io.File.append(path, true); // binary mode
                    pipeIn = sys.io.File.read(path, true);  // keep this for reading
                    connected = true;
                    #if(debug&&(windows||hl)) Main.LOG('discord connected'); #end

                    _send(0, haxe.Json.stringify({v: 1, client_id: clientId}));
                    var response = _read();
                    #if(debug&&(windows||hl)) Main.LOG('handshake: $response'); #end

                    while (connected) {
                        mutex.acquire();
                        var toSend = pendingSend.copy();
                        pendingSend = [];
                        mutex.release();

                        for (msg in toSend)
                            _send(msg.opcode, msg.payload);

                        try {
                            var response = _read();
                            #if(debug&&(windows||hl)) if (response != "") Main.LOG('discord: $response'); #end
                        } catch(_) {}

                        Sys.sleep(0.1);
                    }
                } catch(e:Dynamic) {
                    #if(debug&&(windows||hl)) Main.LOG('discord thread error: $e'); #end
                }
            });
        }

        private function _send(opcode:Int, payload:String):Void {
            var json = haxe.io.Bytes.ofString(payload);
            var len = json.length;
            var buf = haxe.io.Bytes.alloc(8 + len);
            buf.set(0, opcode & 0xFF);
            buf.set(1, (opcode >> 8) & 0xFF);
            buf.set(2, (opcode >> 16) & 0xFF);
            buf.set(3, (opcode >> 24) & 0xFF);
            buf.set(4, len & 0xFF);
            buf.set(5, (len >> 8) & 0xFF);
            buf.set(6, (len >> 16) & 0xFF);
            buf.set(7, (len >> 24) & 0xFF);
            buf.blit(8, json, 0, len);
            pipe.writeBytes(buf, 0, buf.length);
            // no flush() - named pipes auto-flush on write
        }

        // call this from main thread safely
        public function setActivity(state:String, ?details:String):Void {
            var payload:Dynamic;
            if(details!=null){
                payload = haxe.Json.stringify({
                    cmd: "SET_ACTIVITY",
                    args: {
                        pid: 1,
                        activity: {
                            type: "Playing",
                            state: state,
                            details: details,
                            timestamps: {start: Std.int(Date.now().getTime() / 1000)}
                        }
                    },
                    nonce: Std.string(Std.random(99999))
                });
            }else{
                payload = haxe.Json.stringify({
                    cmd: "SET_ACTIVITY",
                    args: {
                        pid: 1,
                        activity: {
                            state: state,
                            timestamps: {start: Std.int(Date.now().getTime() / 1000)}
                        }
                    },
                    nonce: Std.string(Std.random(99999))
                });
            }
            mutex.acquire();
            pendingSend.push({opcode: 1, payload: payload});
            mutex.release();
        }

        private function _read():String {
            var header = haxe.io.Bytes.alloc(8);
            pipeIn.readFullBytes(header, 0, 8);
            var len = header.get(4) | (header.get(5) << 8) | (header.get(6) << 16) | (header.get(7) << 24);
            if (len <= 0 || len > 65536) return "";
            var payload = haxe.io.Bytes.alloc(len);
            pipeIn.readFullBytes(payload, 0, len);
            return payload.getString(0, len);
        }

        public function close():Void {
            if (!connected) return;
            connected = false;
            
            try {
                // send close opcode so discord cleans up properly
                _send(2, "{}");
            } catch(_) {}
            
            Sys.sleep(0.1); // give discord a moment to process it
            
            try { pipe.close(); } catch(_) {}
            try { pipeIn.close(); } catch(_) {}
        }
    }
#end