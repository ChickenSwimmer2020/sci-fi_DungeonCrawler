package backend.ai;

typedef RayResult = {
    startX:Float, startY:Float,
    endX:Float,   endY:Float,
    hit:Dynamic
}

class BaseEnemy extends FlxSprite {
    #if debug
        var debugCanvas:FlxSprite;
    #end

    var rayCount:Int = 35;
    var rayLength:Float = 12;
    public var facingDirection:Int=0; //0 = down, 1 = left, 2 = right, 3 = up
    /**
     * state is how we make the enemies feel a little more, real.
     * normal: (default) normal, idly wander looking for the player or other stuff
     * hurt: enemies health is low, slower movement, and longer reaction times.
     * dead: self-explanitory.
     * confused: enemy saw player far away, and is going to check it out.
     * angry: enemy knows they saw player, but cant find them. (DOES EXTRA DAMANGE IF FOUND (like ultrakill enraged lol))
     */
    public var state:String="normal";
    public var _target:FlxObject = null;
    public var _lastSeenX:Float = 0;
    public var _lastSeenY:Float = 0;
    public var _stateTimer:Float = 0;
    public var _moveTimer:Float = 0;
    public var speed:Float = 30;
    // state thresholds (in tiles)
    public static final CONFUSED_DIST:Float = 10 * 16;
    public static final CHASE_DIST:Float    = 12 * 16;
    public static final ANGRY_DURATION:Float  = 5.0;  // seconds before giving up
    public static final CONFUSED_DURATION:Float = 3.0;

    private static final FOV_RANGE:Float = 90;
    private static final DEG2RAD:Float = Math.PI / 180;

    // preallocated buffers — no allocation per frame
    var _nearby:Array<Dynamic> = [];
    var _results:Array<RayResult> = [];
    var _midPoint:FlxPoint = new FlxPoint();

    // precomputed per facing direction
    static final BASE_ANGLES:Array<Float> = [90, 180, 0, 270];
    function _getPlayerRay():RayResult {
        for (i in 0..._results.length) {
            if (_results[i].hit == "states.PlayState.Player") // replace with your actual player class path
                return _results[i];
        }
        return null;
    }

    public function new(x:Float, y:Float) {
        super(x, y);
        #if debug
            loadGraphic(Paths.DEBUG("enemy"), true, 16, 16);
            animation.add('down_normal',    [0],  1, true);
            animation.add('left_normal',    [1],  1, true);
            animation.add('up_normal',      [2],  1, true);
            animation.add('right_normal',   [3],  1, true);
            animation.add('down_confused',  [4],  1, true);
            animation.add('left_confused',  [5],  1, true);
            animation.add('up_confused',    [6],  1, true);
            animation.add('right_confused', [7],  1, true);
            animation.add('down_angry',     [8],  1, true);
            animation.add('left_angry',     [9],  1, true);
            animation.add('up_angry',       [10], 1, true);
            animation.add('right_angry',    [11], 1, true);

            debugCanvas = new FlxSprite();
            debugCanvas.makeGraphic(FlxG.width, FlxG.height, 0x0, true);
            debugCanvas.scrollFactor.set(0, 0);
            Functions.wait(0.25, (_) -> {
                FlxG.state.add(debugCanvas);
                debugCanvas.camera = Main.camGame;
            });
        #else makeGraphic(4, 4, 0xFFFF0000); #end

        // preallocate result slots so we never alloc in update
        for (i in 0...rayCount)
            _results.push({startX:0, startY:0, endX:0, endY:0, hit:null});
    }
    private var _raycastTimer:Int = 0;
    private final _raycastTimerFrameAmmount:Int=4;
    override public function update(elapsed:Float) {
        super.update(elapsed);

        _stateTimer -= elapsed;
        _moveTimer  -= elapsed;

        _raycastTimer++;
        if (_raycastTimer >= _raycastTimerFrameAmmount) {
            _raycastTimer = 0;
            _rayCast(rayCount, rayLength);
        }

        var playerRay = _getPlayerRay();
        var canSee = playerRay != null;

        switch(state) {
            case "normal":
                if (canSee) {
                    var dist = playerRay.endX - playerRay.startX;
                    var dy   = playerRay.endY - playerRay.startY;
                    var d    = Math.sqrt(dist * dist + dy * dy);
                    if (d >= CONFUSED_DIST)
                        _setState("confused");
                    else
                        _setState("chase");
                } else {
                    _wander(elapsed);
                }

            case "confused":
                _moveToward(_lastSeenX, _lastSeenY, elapsed);
                if (canSee)
                    _setState("chase");
                else if (_stateTimer <= 0)
                    _setState("normal");

            case "chase":
                if (canSee) {
                    _lastSeenX = playerRay.endX;
                    _lastSeenY = playerRay.endY;
                    _moveToward(_lastSeenX, _lastSeenY, elapsed);
                } else {
                    _setState("angry");
                }

            case "angry":
                _moveToward(_lastSeenX, _lastSeenY, elapsed);
                if (canSee)
                    _setState("chase");
                else if (_stateTimer <= 0)
                    _setState("normal");
        }

        #if debug
            debugCanvas.fill(0x0);
            var scrollX = Main.camGame.scroll.x;
            var scrollY = Main.camGame.scroll.y;
            for (i in 0..._results.length) {
                var ray = _results[i];
                FlxSpriteUtil.drawLine(debugCanvas,
                    ray.startX - scrollX, ray.startY - scrollY,
                    ray.endX   - scrollX, ray.endY   - scrollY,
                    ray.hit != null ? {thickness: 0.25, color: 0xFFFF0000} : {thickness: 0.25, color: 0xFF00FF00});
            }
            FlxG.watch.addQuick("enemy state: ", state);
            FlxG.watch.addQuick("can see player: ", canSee);
        #end
    }

    function _setState(newState:String) {
        state = newState;
        switch(state) {
            case "confused": _stateTimer = CONFUSED_DURATION;
            case "angry":    _stateTimer = ANGRY_DURATION;
            case "chase":    _lastSeenX = _results[0].startX; // will be overwritten next frame
        }
        _updateAnimation();
    }

    function _updateAnimation() {
        var stateName = state == "chase" ? "angry" : state;
        animation.play('${["down","left","right","up"][facingDirection]}_${stateName}');
    }

    function _moveToward(targetX:Float, targetY:Float, elapsed:Float) {
        var dx = targetX - (x + width * 0.5);
        var dy = targetY - (y + height * 0.5);

        if (Math.abs(dx) > Math.abs(dy))
            facingDirection = dx > 0 ? 2 : 1;
        else
            facingDirection = dy > 0 ? 0 : 3;

        if (_isWallAhead()) {
            _pickNewDirection();
            return;
        }

        switch(facingDirection) {
            case 0: velocity.set(0, speed);
            case 1: velocity.set(-speed, 0);
            case 2: velocity.set(speed, 0);
            case 3: velocity.set(0, -speed);
        }
    }

    function _wander(elapsed:Float) {
        if (_moveTimer <= 0 || _isWallAhead()) {
            _pickNewDirection();
            _moveTimer = FlxG.random.float(1.0, 3.0);
        }
        switch(facingDirection) {
            case 0: velocity.set(0, speed * 0.5);
            case 1: velocity.set(-speed * 0.5, 0);
            case 2: velocity.set(speed * 0.5, 0);
            case 3: velocity.set(0, -speed * 0.5);
        }
    }

    function _pickNewDirection() {
        facingDirection = FlxG.random.int(0, 3);
    }

    function _isWallAhead():Bool {
        var dirX:Float = 0;
        var dirY:Float = 0;
        switch(facingDirection) {
            case 0: dirY =  1;
            case 1: dirX = -1;
            case 2: dirX =  1;
            case 3: dirY = -1;
        }
        var rx = x + width  * 0.5;
        var ry = y + height * 0.5;
        for (_ in 0...12) {
            rx += dirX;
            ry += dirY;
            for (obj in _nearby) {
                if (Std.isOfType(obj, Tile) && cast(obj, Tile).allowCollisions == ANY) {
                    var t:Tile = cast obj;
                    if (rx >= t.x && rx <= t.x + t.width && ry >= t.y && ry <= t.y + t.height)
                        return true;
                }
            }
        }
        return false;
    }
    /**
     * sends out [rays] rays, and reports back what it sees
     * @param rays how many rays to send out
     * @param length how long each ray should go (IN TILES)
     * @return Array<Dynamic>
     */
    function rayCast(rays:Int, ?length:Float=5):Array<Dynamic> {
        return [for (r in _results) r.hit];
    }

    function _rayCast(rays:Int, ?length:Float=5):Void {
        getGraphicMidpoint(_midPoint); // reuse existing FlxPoint, no alloc
        var midX = _midPoint.x;
        var midY = _midPoint.y;
        var maxDist = length * 16;
        var maxDistSq = (maxDist + 32) * (maxDist + 32);

        var spreadStart = BASE_ANGLES[facingDirection] - FOV_RANGE / 2;
        var angleStep   = FOV_RANGE / (rays - 1);

        // broad-phase cull
        _nearby.resize(0);
        for (obj in GameMap.instance.members) {
            if (obj == this || !obj.alive || !obj.exists) continue;
            var dx = (obj.x + obj.width  * 0.5) - midX;
            var dy = (obj.y + obj.height * 0.5) - midY;
            if (dx * dx + dy * dy <= maxDistSq)
                _nearby.push(obj);
        }

        var nearbyLen = _nearby.length;

        for (i in 0...rays) {
            var angle = (spreadStart + i * angleStep) * DEG2RAD;
            var dirX  = Math.cos(angle);
            var dirY  = Math.sin(angle);
            var x     = midX;
            var y     = midY;
            var dist  = 0.0;
            var hitObj:Dynamic  = null;
            var hitX:Float = midX + dirX * maxDist;
            var hitY:Float = midY + dirY * maxDist;

            while (dist < maxDist) {
                x += dirX;
                y += dirY;
                dist++;

                for (j in 0...nearbyLen) {
                    var obj = _nearby[j];
                    if (x >= obj.x && x <= obj.x + obj.width && y >= obj.y && y <= obj.y + obj.height) {
                        hitObj = obj;
                        hitX = x;
                        hitY = y;
                        break;
                    }
                }
                if (hitObj != null) break;
            }

            // write into preallocated slot
            var r = _results[i];
            r.startX = midX;
            r.startY = midY;
            r.endX   = hitX;
            r.endY   = hitY;
            r.hit    = hitObj != null ? Type.getClassName(Type.getClass(hitObj)) : null;
        }
    }
}