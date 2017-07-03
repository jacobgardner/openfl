package openfl.net;


import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Error;
import haxe.Timer;
import openfl.errors.IOError;
import openfl.errors.SecurityError;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.Lib;

#if (js && html5)
import js.html.ArrayBuffer;
import js.Browser;
#end

#if sys
import sys.net.Host;
import sys.net.Socket in SysSocket;
#end


class Socket extends EventDispatcher implements IDataInput implements IDataOutput {
	
	
	private static var __nextID = 0;
	
	public var bytesAvailable (get, never):Int;
	public var bytesPending (get, never):Int;
	public var connected (get, never):Bool;
	public var objectEncoding:UInt;
	public var secure:Bool;
	public var timeout:Int;
	public var endian (get, set):Endian;
	
	private var __buffer:Bytes;
	private var __connected:Bool;
	private var __endian:Endian;
	private var __host:String;
	private var __input:ByteArray;
	private var __inputBuffer:ByteArray;
	private var __output:ByteArray;
	private var __port:Int;
	private var __timestamp:Float;
	
	#if html5
	private var __socket:JSSocket;
	private var __socketID:String;
	#elseif sys
	private var __socket:SysSocket;
	#else
	private var __socket:Dynamic;
	#end
	
	
	public function new (host:String = null, port:Int = 0) {
		
		super ();
		
		endian = Endian.BIG_ENDIAN;
		timeout = 20000;
		
		__buffer = Bytes.alloc (4096);
		
		if (port > 0 && port < 65535) {
			
			connect (host, port);
			
		}
		
	}
	
	
	public function connect (host:String = null, port:Int = 0):Void {
		
		if (__socket != null) {
			
			close ();
			
		}
		
		if (port < 0 || port > 65535) {
			
			throw new SecurityError ("Invalid socket port number specified.");
			
		}
		
		#if sys
		
		var h:Host = null;
		
		try {
			
			h = new Host (host);
			
		} catch (e:Dynamic) {
			
			dispatchEvent (new IOErrorEvent (IOErrorEvent.IO_ERROR, true, false, "Invalid host"));
			return;
			
		}
		
		__timestamp = Sys.time ();
		
		#end
		
		__host = host;
		__port = port;
		
		__output = new ByteArray ();
		__output.endian = __endian;
		
		__input = new ByteArray ();
		__input.endian = __endian;
		
		#if html5
		
		__inputBuffer = new ByteArray ();
		__inputBuffer.endian = __endian;
		
		var protocol = "http:";
		
		if (secure || Browser.location.protocol == 'https:') {
			
			protocol = "https:";
			
		}
		
		__socketID = "openfl" + (__nextID++);
		__socket = SocketIO.connect (protocol + "//" + host + ":" + port, { timeout: timeout });
		__socket.on ("connect", socket_onConnect);
		__socket.on ("connect_error", socket_onConnectError);
		__socket.on ("connect_timeout", socket_onConnectTimeout);
		__socket.on ("disconnect", socket_onDisconnect);
		__socket.on (__socketID, socket_onMessage);
		
		#elseif sys
		
		__socket = new SysSocket ();
		__socket.setBlocking (false);
		__socket.setFastSend (true);
		
		try {
			
			__socket.connect (h, port);
			
		} catch (e:Dynamic) {}
		
		#end
		
		Lib.current.addEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		
	}
	
	
	public function close ():Void {
		
		if ( __socket != null) {
			
			__cleanSocket ();
			
		} else {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
	}
	
	
	public function flush ():Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		if (__output.length > 0) {
			
			try {
				
				#if (js && html5)
				var buffer:ArrayBuffer = __output;
				if (buffer.byteLength > __output.length) buffer = buffer.slice (0, __output.length);
				__socket.emit (__socketID, buffer);
				#else
				__socket.output.writeBytes (__output, 0, __output.length);
				#end
				__output = new ByteArray ();
				__output.endian = __endian;
				
			} catch (e:Dynamic) {
				
				throw new IOError ("Operation attempted on invalid socket.");
				
			}
			
		}
		
	}
	
	
	public function readBoolean ():Bool {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readBoolean ();
		
	}
	
	
	public function readByte ():Int {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readByte ();
		
	}
	
	
	public function readBytes (bytes:ByteArray, offset:Int = 0, length:Int = 0):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__input.readBytes (bytes, offset, length);
		
	}
	
	
	public function readDouble ():Float {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readDouble ();
		
	}
	
	
	public function readFloat ():Float {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readFloat ();
		
	}
	
	
	public function readInt ():Int {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readInt ();
		
	}
	
	
	public function readMultiByte (length:Int, charSet:String):String {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readMultiByte (length, charSet);
		
	}
	
	
	//public function readObject ():Dynamic {
		//
		//return __input.readObject ();
		//
	//}
	
	
	public function readShort ():Int {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readShort ();
		
	}
	
	
	public function readUnsignedByte ():Int {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		return __input.readUnsignedByte ();
		
	}
	
	
	public function readUnsignedInt ():Int {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readUnsignedInt ();
		
	}
	
	
	public function readUnsignedShort ():Int {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readUnsignedShort ();
		
	}
	
	
	public function readUTF ():String {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readUTF ();
		
	}
	
	
	public function readUTFBytes (length:Int):String {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		return __input.readUTFBytes (length);
		
	}
	
	
	public function writeBoolean (value:Bool):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeBoolean (value);
		
	}
	
	
	public function writeByte (value:Int):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeByte (value);
		
	}
	
	
	public function writeBytes (bytes:ByteArray, offset:Int = 0, length:Int = 0):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeBytes (bytes, offset, length);
		
	}
	
	
	public function writeDouble (value:Float):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeDouble (value);
		
	}
	
	
	public function writeFloat (value:Float):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeFloat (value);
		
	}
	
	
	public function writeInt (value:Int):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeInt (value);
		
	}
	
	
	public function writeMultiByte (value:String, charSet:String):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeUTFBytes (value);
		
	}
	
	
	//public function writeObject (object:Dynamic):Void {
		//
		//__output.writeObject (object);
		//
	//}
	
	
	public function writeShort (value:Int):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeShort (value);
		
	}
	
	
	public function writeUnsignedInt (value:Int):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeUnsignedInt (value);
		
	}
	
	
	public function writeUTF (value:String):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeUTF (value);
		
	}
	
	
	public function writeUTFBytes (value:String):Void {
		
		if (__socket == null) {
			
			throw new IOError ("Operation attempted on invalid socket.");
			
		}
		
		__output.writeUTFBytes (value);
		
	}
	
	
	private function __cleanSocket ():Void {
		
		if (__socket != null) {
			
			#if sys
			try {
				
				__socket.close ();
				
			} catch (e:Dynamic) {}
			#end
			
			__socket = null;
			__connected = false;
			Lib.current.removeEventListener (Event.ENTER_FRAME, this_onEnterFrame);
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function socket_onConnect (_):Void {
		
		__connected = true;
		dispatchEvent (new Event (Event.CONNECT));
		
	}
	
	
	private function socket_onConnectError (_):Void {
		
		__cleanSocket ();
		dispatchEvent (new IOErrorEvent (IOErrorEvent.IO_ERROR, true, false, "Connection failed"));
		
	}
	
	
	private function socket_onConnectTimeout (_):Void {
		
		socket_onDisconnect (_);
		
	}
	
	
	private function socket_onDisconnect (_):Void {
		
		__cleanSocket ();
		dispatchEvent (new Event (Event.CLOSE));
		
	}
	
	
	private function socket_onError (_):Void {
		
		__cleanSocket ();
		dispatchEvent (new Event (IOErrorEvent.IO_ERROR));
		
	}
	
	
	private function socket_onMessage (data:ArrayBuffer):Void {
		
		var newData:ByteArray = data;
		newData.readBytes (__inputBuffer, __inputBuffer.length);
		
	}
	
	
	private function this_onEnterFrame (event:Event):Void {
		
		#if html5
		
		if (__inputBuffer.bytesAvailable > 0) {
			
			var newInput = new ByteArray ();
			var newDataLength = __inputBuffer.bytesAvailable;
			
			__input.readBytes (newInput, 0, __input.bytesAvailable);
			__inputBuffer.position = 0;
			__inputBuffer.readBytes (newInput, newInput.position, __inputBuffer.length);
			
			newInput.position = 0;
			
			__input = newInput;
			__inputBuffer.clear ();
			
			dispatchEvent (new ProgressEvent (ProgressEvent.SOCKET_DATA, false, false, newDataLength, 0));
			
		}
		
		if (__socket != null) {
			
			flush ();
			
		}
		
		#else
		
		var doConnect = false;
		var doClose = false;
		
		if (!connected) {
			
			var r = SysSocket.select (null, [ __socket ], null, 0);
			
			if (r.write[0] == __socket) {
				
				doConnect = true;
				
			} else if (Sys.time () - __timestamp > timeout / 1000) {
				
				doClose = true;
				
			}
			
		}
		
		var b = new BytesBuffer ();
		var bLength = 0;
		
		if (connected || doConnect) {
			
			try {
				
				var l:Int;
				
				do {
					
					l = __socket.input.readBytes (__buffer, 0, __buffer.length);
					
					if (l > 0) {
						
						b.addBytes (__buffer, 0, l);
						bLength += l;
						
					}
					
				} while (l == __buffer.length);
				
			} catch (e:Error) {
				
				if (e != Error.Blocked) {
					
					doClose = true;
					
				}
				
			} catch (e:Dynamic) {
				
				doClose = true;
				
			}
			
		}
		
		if (doClose && connected) {
			
			__cleanSocket ();
			
			dispatchEvent (new Event (Event.CLOSE));
			
		} else if (doClose) {
			
			__cleanSocket ();
			
			dispatchEvent (new IOErrorEvent (IOErrorEvent.IO_ERROR, true, false, "Connection failed"));
			
		} else if (doConnect) {
			
			__connected = true;
			dispatchEvent (new Event (Event.CONNECT));
			
		}
		
		if (bLength > 0) {
			
			var newData = b.getBytes ();
			
			var rl = __input.length - __input.position;
			if (rl < 0) rl = 0;
			
			var newInput = Bytes.alloc (rl + newData.length);
			if (rl > 0) newInput.blit (0, __input, __input.position, rl);
			newInput.blit (rl, newData, 0, newData.length);
			__input = newInput;
			
			dispatchEvent (new ProgressEvent (ProgressEvent.SOCKET_DATA, false, false, newData.length, 0));
			
		}
		
		if (__socket != null) {
			
			try {
				
				flush ();
				
			} catch (e:IOError) {
				
				dispatchEvent (new IOErrorEvent (IOErrorEvent.IO_ERROR, true, false, e.message));
				
			}
			
		}
		
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_bytesAvailable ():Int {
		
		return __input.bytesAvailable;
		
	}
	
	
	private function get_bytesPending ():Int {
		
		return __output.length;
		
	}
	
	
	private function get_connected ():Bool {
		
		return __connected;
		
	}
	
	
	private function get_endian ():Endian {
		
		return __endian;
		
	}
	
	
	private function set_endian (value:Endian):Endian {
		
		__endian = value;
		
		if (__input != null) __input.endian = value;
		if (__inputBuffer != null) __inputBuffer.endian = value;
		if (__output != null) __output.endian = value;
		
		return __endian;
		
	}
	
	
}


#if html5
@:native("io") extern class SocketIO {
	
	@:selfCall
	public function new ():Void;
	public static function connect (url:String, ?options:Dynamic):JSSocket;
	
}

extern class JSSocket {
	
	public function disconnect():Void;
	public function on (event:String, ?callback:Dynamic):Void;
	public function emit (event:String, ?data:Dynamic):Void;
	
}
#end