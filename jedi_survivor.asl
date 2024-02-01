// Star Wars Jedi: Survivor Autosplitter
// by Xero

state ("JediSurvivor")
{

}

startup
{

}

init
{
    IntPtr loadStartPtr = game.MainModule.BaseAddress + 0x11D2DC0;
    IntPtr loadEndPtr = game.MainModule.BaseAddress + 0x11D2698;

    vars.isLoadingDetourPtr = game.AllocateMemory(64);
	
	var isLoadingDetourBytes = new byte[] {
		0x48, 0x8B, 0x9C, 0x28, 0x80, 0x00, 0x00, 0x00,	// mov rbx,[rsp+00000080] 	# JediSurvivor.exe+11D2DC0
		0x48, 0x8B, 0x88, 0x30, 0x01, 0x00, 0x00,		// mov rcx,[rax+00000130] 	# JediSurvivor.exe+11D2DC8
		0x48, 0x85, 0xC9,								// test rcx,rcx				# JediSurvivor.exe+11D2DCF

		0xC7, 0x05, 0x23, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,		// mov [vars.isLoadingDetourPtr + 3F], 00000001

		0xC3, 											// ret
		0xCC, 0xCC, 0xCC,								// 32 bytes

		0xC6, 0x87, 0x88, 0x00, 0x00, 0x00, 0x02,					// mov byte ptr [rdi+00000088],02	# JediSurvivor.exe+11D2698
		0xC7, 0x87, 0x8C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// mov [rdi+0000008C],00000000		# JediSurvivor.exe+11D269F

		0xC7, 0x05, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,		// mov [vars.isLoadingDetourPtr + 3F], 00000000

		0xC3,

		0xCC, 0xCC, 0xCC,
		0x00,				// byte to be read, last one
	};

	var loadStartDetourBytes = new List<byte>() {
		0xFF, 0x15, 0x02, 0x00, 0x00, 0x00, 0xEB, 0x08 // call to absolute 64-bit address
	};
	loadStartDetourBytes.AddRange(BitConverter.GetBytes((ulong)vars.isLoadingDetourPtr));
	loadStartDetourBytes.AddRange(new byte[] {0x90, 0x90}); // add two nops
	
	var loadEndDetourBytes = new List<byte>() {
		0xFF, 0x15, 0x02, 0x00, 0x00, 0x00, 0xEB, 0x08 // call to absolute 64-bit address
	};
	loadEndDetourBytes.AddRange(BitConverter.GetBytes((ulong)vars.isLoadingDetourPtr + 0x20)); // offset by 32 bytes
	loadEndDetourBytes.AddRange(new byte[] {0x90}); // add single nop

	// wait 15 seconds then suspend game while writing so it doesn't crash
	Thread.Sleep(15000);
	game.Suspend();
	try {
		// write the detour code at the allocated memory address
		print("[SWJS Autosplitter] Writing detoured code...");
		game.WriteBytes((IntPtr)vars.isLoadingDetourPtr, isLoadingDetourBytes);

		// write detour calls
		print("[SWJS Autosplitter] Writing loading start detour...");
		game.WriteBytes(loadStartPtr, loadStartDetourBytes.ToArray());
		print("[SWJS Autosplitter] Writing loading end detour...");
		game.WriteBytes(loadEndPtr, loadEndDetourBytes.ToArray());
	}
	catch {
		print("[SWJS Autosplitter] ------------");
		print("[SWJS Autosplitter] Fatal Error!");
		print("[SWJS Autosplitter] ");
		print("[SWJS Autosplitter] Detours could not be set.");
		print("[SWJS Autosplitter] ------------");
		vars.FreeMemory(game);
		throw;
	}
	finally {
		print("[SWJS Autosplitter] Detour successful!");
		game.Resume();
	}
}

start
{

}

reset 
{

}

split
{

}

update
{
    current.isLoading = game.ReadValue<bool>((IntPtr)vars.isLoadingDetourPtr+0x3F);
}

isLoading
{	
	return current.isLoading;
}