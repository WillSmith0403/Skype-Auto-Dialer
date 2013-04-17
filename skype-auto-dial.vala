[DBus (name = "com.Skype.API")]
interface Skype : Object {
     public abstract string invoke (string cmd) throws IOError;
}

errordomain ApplicationArgumentError {
	MISSING_ARGUMENT,
	INCORRECT_ARGUMENT
}

string _number;
string _extension;

int main (string[] args) {
    try {
		parse_arguments(args);
		Skype skype= skype_init();
		string? call_id= skype_call_and_wait(skype, _number);
		if (call_id == null) {
			return 1;
		}
		if (_extension.length != 0) {
			Thread.usleep (1000 * 1000);
			skype_dial_dtmf(skype, call_id, _extension);
		}
	} catch (Error e) {
        stderr.printf ("%s\n", e.message);
		usage();
        return 1;
    }

    return 0;
}

void usage() {
	stdout.printf("Usage: <program> <phone number> [extension]\n");
	stdout.printf("Where:\n");
	stdout.printf("     <phone number> - The phone number to dial. The number must not contain spaces. \n");
	stdout.printf("     [extension]    - The extension to dial after the call has been established (Optional) \n");

}

void parse_arguments(string[] args) throws ApplicationArgumentError {
	_number= "";
	_extension= "";
	
	if (args.length < 2) {
		throw new ApplicationArgumentError.MISSING_ARGUMENT("Missing phone number argument");
	}
	
	_number= args[1];
	_number= _number.replace(" ", "");

	if (!new Regex("""^\+?\d+$""").match(_number)) {
		throw new ApplicationArgumentError.INCORRECT_ARGUMENT("The number '" + args[1] + "' is not a valid phone number");
	}

	if (args.length >= 2) {
		_extension= args[2];
		_extension= _extension.replace(" ", "");
		
		if (!new Regex("""^[0-9#\*]+$""").match(_extension)) {
			throw new ApplicationArgumentError.INCORRECT_ARGUMENT("The extension '" + args[2] + "' is not a valid. Valid characters are 0-9 and # and *");
		}
	}
}

Skype skype_init() throws IOError {
	Skype skype = Bus.get_proxy_sync (BusType.SESSION, "com.Skype.API", "/com/Skype");
	skype_check (skype, "NAME Auto-Extension-Dialer", "OK");
	skype_check (skype, "PROTOCOL 1", "PROTOCOL 1");
	return skype;
}

string? skype_call_and_wait(Skype skype, string number) throws IOError {
	string[] response= skype_send_split(skype, "CALL " + number);
	string id= response[1];
	
	while (true) {
		Thread.usleep (500 * 1000);
		response= skype_send_split(skype, "GET CALL " + id + " STATUS");
		if (response[0] == "ERROR" || response[3] == "FINISHED" ) {
			return null;
		}
		if (response[3] == "INPROGRESS") {
			break;
		}
	}
	return id;
}

void skype_dial_dtmf(Skype skype, string call_id, string extension) throws IOError {
	unichar c;
	for (int i = 0; extension.get_next_char (ref i, out c);) {
		skype_send(skype, "SET CALL " + call_id + " DTMF " + c.to_string());
	}
}

string[] skype_send_split(Skype skype, string cmd) throws IOError {
     return skype.invoke (cmd).split(" ");
}


string skype_send(Skype skype, string cmd) throws IOError {
     return skype.invoke (cmd);
}

void skype_check(Skype skype, string cmd, string expected) throws IOError {
    string actual = skype_send (skype, cmd);
    if (actual != expected) {
        stderr.printf ("Bad result '%s', expected '%s'\n", actual, expected);
    }
}
