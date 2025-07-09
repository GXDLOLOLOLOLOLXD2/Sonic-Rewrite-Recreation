package backend;

import Sys.sleep;
import lime.app.Application;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

class DiscordClient // old are "class DiscordClient"
{
	public static var isInitialized:Bool = false;
	private static final _defaultID:String = "863222024192262205";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordRichPresence = #if (hxdiscord_rpc > "1.2.4") new DiscordRichPresence(); #else DiscordRichPresence.create(); #end

	public static function check()
	{
		#if desktop
		if(ClientPrefs.data.discordRPC) initialize();
		else if(isInitialized) shutdown();
		#end
	}
	
	public static function prepare()
	{
		#if desktop
		if (!isInitialized && ClientPrefs.data.discordRPC)
			initialize();

		Application.current.window.onClose.add(function() {
			if(isInitialized) shutdown();
		});
		#end
	}

	public dynamic static function shutdown() {
		#if desktop
		Discord.Shutdown();
		isInitialized = false;
		#end
	}
	
	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		#if desktop
		var requestPtr:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) //New Discord IDs/Discriminator system
			trace('(Discord) Connected to User (${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)})');
		else //Old discriminators
			trace('(Discord) Connected to User (${cast(requestPtr.username, String)})');

		changePresence();
		#end
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		#if desktop
		trace('Discord: Error ($errorCode: ${cast(message, String)})');
		#end
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		#if desktop
		trace('Discord: Disconnected ($errorCode: ${cast(message, String)})');
		#end
	}

	public static function initialize()
	{
		#if desktop
		var discordHandlers:DiscordEventHandlers = #if (hxdiscord_rpc > "1.2.4") new DiscordEventHandlers(); #else DiscordEventHandlers.create(); #end
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), #if (hxdiscord_rpc > "1.2.4") false #else 1 #end, null);

		if(!isInitialized) trace("Discord Client initialized");

		sys.thread.Thread.create(() ->
		{
			var localID:String = clientID;
			while (localID == clientID)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();

				// Wait 0.5 seconds until the next loop...
				Sys.sleep(0.5);
			}
		});
		isInitialized = true;
		#end
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		#if desktop
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = 'icon';
		presence.largeImageText = "Engine Version: " + states.MainMenuState.psychEngineVersion;
		presence.smallImageKey = smallImageKey;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
		#end
	}

	public static function updatePresence() {
		#if desktop
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
		#end
	}
	
	public static function resetClientID() {
		#if desktop
		clientID = _defaultID;
		#end
	}

	private static function set_clientID(newID:String)
	{
		#if desktop
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
		#end
	}

	#if DISCORD_ALLOWED // (MODS_ALLOWED && DISCORD_ALLOWED)
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if(pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			//trace('Changing clientID! $clientID, $_defaultID');
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		#if desktop
		Lua_helper.add_callback(lua, "changeDiscordPresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});

		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String = null) {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
		#end
	}
	#end
}
