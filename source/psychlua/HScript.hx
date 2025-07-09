package psychlua;

import flixel.FlxBasic;
import objects.Character;
import psychlua.LuaUtils;
import psychlua.CustomSubstate;
import hscript.Parser;
import hscript.Interp;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

// A HScript with interaction with Lua (using real HScript for dinamic code without SScript)
// by GXDLOLOLOLOLOLXD2

#if HSCRIPT_ALLOWED
class HScript
{
    public var modFolder:String;
    public var origin:String;
    public var interp:Interp;
    public var parentLua:FunkinLua = null;
    public var varsToBring:Any = null;

    #if LUA_ALLOWED
    public static function initHaxeModule(parent:FunkinLua)
    {
        if(parent.hscript == null)
        {
            trace('initializing haxe interp for: ${parent.scriptName}');
            parent.hscript = new HScript(parent);
        }
    }

    public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
    {
        var hs:HScript = try parent.hscript catch (e) null;
        if(hs == null)
        {
            trace('initializing haxe interp for: ${parent.scriptName}');
            parent.hscript = new HScript(parent, code, varsToBring);
        }
        else
        {
            parent.hscript.runCode(code);
        }
    }
    #end

    public function new(?parent:Dynamic, ?fileOrCode:String = null, ?varsToBring:Any = null)
    {
        this.varsToBring = varsToBring;
        interp = new Interp();

        #if LUA_ALLOWED
        parentLua = parent;
        if (parent != null)
        {
            this.origin = parent.scriptName;
            this.modFolder = parent.modFolder;
        }
        #end

        if (fileOrCode != null && fileOrCode.length > 0)
        {
            this.origin = fileOrCode;
        }

        preset();

        // if fileOrCode are a code the game executes he
        if (fileOrCode != null && fileOrCode.length > 0)
        {
            runCode(fileOrCode);
        }
    }

    function preset() {
        // Global Variables
        interp.variables.set("FlxG", flixel.FlxG);
        interp.variables.set("FlxMath", flixel.math.FlxMath);
        interp.variables.set("FlxSprite", flixel.FlxSprite);
        interp.variables.set("FlxCamera", flixel.FlxCamera);
        interp.variables.set("PsychCamera", backend.PsychCamera);
        interp.variables.set("FlxTimer", flixel.util.FlxTimer);
        interp.variables.set("FlxTween", flixel.tweens.FlxTween);
        interp.variables.set("FlxEase", flixel.tweens.FlxEase);
        interp.variables.set("FlxColor", CustomFlxColor);
        interp.variables.set("Countdown", backend.BaseStage.Countdown);
        interp.variables.set("PlayState", PlayState);
        interp.variables.set("Paths", Paths);
        interp.variables.set("StorageUtil", StorageUtil);
        interp.variables.set("Conductor", Conductor);
        interp.variables.set("ClientPrefs", ClientPrefs);
        #if ACHIEVEMENTS_ALLOWED
        interp.variables.set("Achievements", Achievements);
        #end
        interp.variables.set("Character", Character);
        interp.variables.set("Alphabet", Alphabet);
        interp.variables.set("Note", objects.Note);
        interp.variables.set("CustomSubstate", CustomSubstate);
        #if (!flash && sys)
        interp.variables.set("FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);
        #end
        interp.variables.set("ShaderFilter", openfl.filters.ShaderFilter);
        interp.variables.set("StringTools", StringTools);
        #if flxanimate
        interp.variables.set("FlxAnimate", FlxAnimate);
        #end

        // Variables
        interp.variables.set('setVar', function(name:String, value:Dynamic) {
            PlayState.instance.variables.set(name, value);
            return value;
        });
        interp.variables.set('getVar', function(name:String) {
            var result:Dynamic = null;
            if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
            return result;
        });
        interp.variables.set('removeVar', function(name:String)
        {
            if(PlayState.instance.variables.exists(name))
            {
                PlayState.instance.variables.remove(name);
                return true;
            }
            return false;
        });
        interp.variables.set('debugPrint', function(text:String, ?color:FlxColor = null) {
            if(color == null) color = FlxColor.WHITE;
            PlayState.instance.addTextToDebug(text, color);
        });
        interp.variables.set('getModSetting', function(saveTag:String, ?modName:String = null) {
            if(modName == null)
            {
                if(this.modFolder == null)
                {
                    PlayState.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
                    return null;
                }
                modName = this.modFolder;
            }
            return LuaUtils.getModSetting(saveTag, modName);
        });

        // Keyboard & Gamepads
        interp.variables.set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
        interp.variables.set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
        interp.variables.set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

        interp.variables.set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
        interp.variables.set('anyGamepadPressed', function(name:String) return FlxG.gamepads.anyPressed(name));
        interp.variables.set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

        interp.variables.set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true)
        {
            var controller = FlxG.gamepads.getByID(id);
            if (controller == null) return 0.0;
            return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
        });
        interp.variables.set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true)
        {
            var controller = FlxG.gamepads.getByID(id);
            if (controller == null) return 0.0;
            return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
        });
        interp.variables.set('gamepadJustPressed', function(id:Int, name:String)
        {
            var controller = FlxG.gamepads.getByID(id);
            if (controller == null) return false;
            return Reflect.getProperty(controller.justPressed, name) == true;
        });
        interp.variables.set('gamepadPressed', function(id:Int, name:String)
        {
            var controller = FlxG.gamepads.getByID(id);
            if (controller == null) return false;
            return Reflect.getProperty(controller.pressed, name) == true;
        });
        interp.variables.set('gamepadReleased', function(id:Int, name:String)
        {
            var controller = FlxG.gamepads.getByID(id);
            if (controller == null) return false;
            return Reflect.getProperty(controller.justReleased, name) == true;
        });

        interp.variables.set('keyJustPressed', function(name:String = '') {
            name = name.toLowerCase();
            switch(name) {
                case 'left': return Controls.instance.NOTE_LEFT_P;
                case 'down': return Controls.instance.NOTE_DOWN_P;
                case 'up': return Controls.instance.NOTE_UP_P;
                case 'right': return Controls.instance.NOTE_RIGHT_P;
                default: return Controls.instance.justPressed(name);
            }
            return false;
        });
        interp.variables.set('keyPressed', function(name:String = '') {
            name = name.toLowerCase();
            switch(name) {
                case 'left': return Controls.instance.NOTE_LEFT;
                case 'down': return Controls.instance.NOTE_DOWN;
                case 'up': return Controls.instance.NOTE_UP;
                case 'right': return Controls.instance.NOTE_RIGHT;
                default: return Controls.instance.pressed(name);
            }
            return false;
        });
        interp.variables.set('keyReleased', function(name:String = '') {
            name = name.toLowerCase();
            switch(name) {
                case 'left': return Controls.instance.NOTE_LEFT_R;
                case 'down': return Controls.instance.NOTE_DOWN_R;
                case 'up': return Controls.instance.NOTE_UP_R;
                case 'right': return Controls.instance.NOTE_RIGHT_R;
                default: return Controls.instance.justReleased(name);
            }
            return false;
        });

        // Callbacks for Lua
        #if LUA_ALLOWED
        interp.variables.set('createGlobalCallback', function(name:String, func:Dynamic)
        {
            for (script in PlayState.instance.luaArray)
                if(script != null && script.lua != null && !script.closed)
                    Lua_helper.add_callback(script.lua, name, func);

            FunkinLua.customFunctions.set(name, func);
        });

        interp.variables.set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
        {
            if(funk == null) funk = parentLua;
            if(parentLua != null) funk.addLocalCallback(name, func);
            else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
        });
        #end

        interp.variables.set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
            try {
                var str:String = '';
                if(libPackage.length > 0)
                    str = libPackage + '.';
                interp.variables.set(libName, Type.resolveClass(str + libName));
            }
            catch (e:Dynamic) {
                var msg:String = e.message.substr(0, e.message.indexOf('\n'));
                #if LUA_ALLOWED
                if(parentLua != null)
                {
                    FunkinLua.lastCalledScript = parentLua;
                    FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
                    return;
                }
                #end
                if(PlayState.instance != null) PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
                else trace('$origin - $msg');
            }
        });

        #if LUA_ALLOWED
        interp.variables.set('parentLua', parentLua);
        #else
        interp.variables.set('parentLua', null);
        #end
        interp.variables.set('this', this);
        interp.variables.set('game', FlxG.state);

        interp.variables.set('buildTarget', LuaUtils.getBuildTarget());
        interp.variables.set('customSubstate', CustomSubstate.instance);
        interp.variables.set('customSubstateName', CustomSubstate.name);

        interp.variables.set('Function_Stop', LuaUtils.Function_Stop);
        interp.variables.set('Function_Continue', LuaUtils.Function_Continue);
        interp.variables.set('Function_StopLua', LuaUtils.Function_StopLua);
        interp.variables.set('Function_StopHScript', LuaUtils.Function_StopHScript);
        interp.variables.set('Function_StopAll', LuaUtils.Function_StopAll);

        interp.variables.set('add', FlxG.state.add);
        interp.variables.set('insert', FlxG.state.insert);
        interp.variables.set('remove', FlxG.state.remove);

        if(PlayState.instance == FlxG.state)
        {
            interp.variables.set('addBehindGF', PlayState.instance.addBehindGF);
            interp.variables.set('addBehindDad', PlayState.instance.addBehindDad);
            interp.variables.set('addBehindBF', PlayState.instance.addBehindBF);
            // setSpecialObject can be adapted if necessary
        }

        // TouchPad (if necessary)
        #if LUA_ALLOWED
        interp.variables.set("addTouchPad", (DPadMode:String, ActionMode:String) -> {
            PlayState.instance.makeLuaTouchPad(DPadMode, ActionMode);
            PlayState.instance.addLuaTouchPad();
        });

        interp.variables.set("removeTouchPad", () -> {
            PlayState.instance.removeLuaTouchPad();
        });

        interp.variables.set("addTouchPadCamera", () -> {
            if(PlayState.instance.luaTouchPad == null){
                FunkinLua.luaTrace('addTouchPadCamera: TPAD does not exist.');
                return;
            }
            PlayState.instance.addLuaTouchPadCamera();
        });

        interp.variables.set("touchPadJustPressed", function(button:Dynamic):Bool {
            if(PlayState.instance.luaTouchPad == null){
                return false;
            }
            return PlayState.instance.luaTouchPadJustPressed(button);
        });

        interp.variables.set("touchPadPressed", function(button:Dynamic):Bool {
            if(PlayState.instance.luaTouchPad == null){
                return false;
            }
            return PlayState.instance.luaTouchPadPressed(button);
        });

        interp.variables.set("touchPadJustReleased", function(button:Dynamic):Bool {
            if(PlayState.instance.luaTouchPad == null){
                return false;
            }
            return PlayState.instance.luaTouchPadJustReleased(button);
        });
        #end

        // Extra variables for modsds
        if(varsToBring != null) {
            for (key in Reflect.fields(varsToBring)) {
                key = key.trim();
                var value = Reflect.field(varsToBring, key);
                interp.variables.set(key, value);
            }
            varsToBring = null;
        }
    }

    public function runCode(code:String):Dynamic {
        try {
            var parser = new Parser();
            var program = parser.parseString(code);
            return interp.execute(program);
        } catch (e:Dynamic) {
            PlayState.instance.addTextToDebug('HScript ERROR (${origin}): ${e}', FlxColor.RED);
            return null;
        }
    }

    public function destroy()
    {
        origin = null;
        interp = null;
        #if LUA_ALLOWED parentLua = null; #end
    }

    #if LUA_ALLOWED
    public static function implement(funk:FunkinLua) {
        funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null):Dynamic {
            if(funk.hscript != null)
                return funk.hscript.runCode(codeToRun);
            FunkinLua.luaTrace("runHaxeCode: HScript não está inicializado!", false, false, FlxColor.RED);
            return null;
        });
    }
    #end
}

class CustomFlxColor {
    public static var TRANSPARENT(default, null):Int = FlxColor.TRANSPARENT;
    public static var BLACK(default, null):Int = FlxColor.BLACK;
    public static var WHITE(default, null):Int = FlxColor.WHITE;
    public static var GRAY(default, null):Int = FlxColor.GRAY;

    public static var GREEN(default, null):Int = FlxColor.GREEN;
    public static var LIME(default, null):Int = FlxColor.LIME;
    public static var YELLOW(default, null):Int = FlxColor.YELLOW;
    public static var ORANGE(default, null):Int = FlxColor.ORANGE;
    public static var RED(default, null):Int = FlxColor.RED;
    public static var PURPLE(default, null):Int = FlxColor.PURPLE;
    public static var BLUE(default, null):Int = FlxColor.BLUE;
    public static var BROWN(default, null):Int = FlxColor.BROWN;
    public static var PINK(default, null):Int = FlxColor.PINK;
    public static var MAGENTA(default, null):Int = FlxColor.MAGENTA;
    public static var CYAN(default, null):Int = FlxColor.CYAN;

    public static function fromInt(Value:Int):Int 
    {
        return cast FlxColor.fromInt(Value);
    }

    public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
    {
        return cast FlxColor.fromRGB(Red, Green, Blue, Alpha);
    }
    public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
    {	
        return cast FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);
    }

    public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Int
    {
        return cast FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);
    }

    public static function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
    {	
        return cast FlxColor.fromHSB(Hue, Sat, Brt, Alpha);
    }
    public static function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
    {	
        return cast FlxColor.fromHSL(Hue, Sat, Light, Alpha);
    }
    public static function fromString(str:String):Int
    {
        return cast FlxColor.fromString(str);
    }
}
#end
