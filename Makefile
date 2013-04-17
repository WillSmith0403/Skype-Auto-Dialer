
all: skype-auto-dial

skype-auto-dial: skype-auto-dial.vala
	valac --pkg gio-2.0 skype-auto-dial.vala
