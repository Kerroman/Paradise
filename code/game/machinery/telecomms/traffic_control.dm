/obj/machinery/computer/telecomms/traffic
	name = "Telecommunications Traffic Control"

	var/screen = 0				// the screen number:
	var/list/servers = list()	// the servers located by the computer
	var/mob/editingcode
	var/mob/lasteditor
	var/obj/machinery/telecomms/server/SelectedServer

	var/compiling_errors = ""

	var/network = "NULL"		// the network to probe
	var/temp = ""				// temporary feedback messages

	var/storedcode = ""			// code stored

	light_color = LIGHT_COLOR_DARKGREEN

	req_access = list(access_tcomsat)
	circuit = /obj/item/weapon/circuitboard/comm_traffic

/obj/machinery/computer/telecomms/traffic/attack_hand(mob/user)
	interact(user)

/obj/machinery/computer/telecomms/traffic/interact(mob/user)
	if(stat & (BROKEN|NOPOWER))
		return 0

	user.set_machine(src)

	if(!editingcode || editingcode && editingcode.machine != src)
		editingcode = user
		lasteditor = user

	var/dat = ""

	dat +=  "<center><b>Telecommunications Traffic Control</b></center>"

	if(screen == 0) //main menu
		dat += "<br>[temp]</br>"
		dat += "<br>Current Network: <a href='?src=\ref[src];network=1'>[network]</a><br>"
		if(servers.len)
			dat += "<br>Detected Telecommunication Servers:<ul>"
			for(var/obj/machinery/telecomms/T in servers)
				dat += "<li><a href='?src=\ref[src];viewserver=[T.id]'>\ref[T] [T.name]</a> ([T.id])</li>"
			dat += "</ul>"

			dat += "<br><a href='?src=\ref[src];operation=release'>\[Flush Buffer\]</a>"

		else
			dat += "<br>No servers detected. Scan for servers: <a href='?src=\ref[src];operation=scan'>\[Scan\]</a>"

	if(screen == 1) //server menu
		dat += "<br>[temp]<br>"
		dat += "<center><a href='?src=\ref[src];operation=mainmenu'>\[Main Menu\]</a>     <a href='?src=\ref[src];operation=refresh'>\[Refresh\]</a></center>"
		dat += "<br>Current Network: [network]"
		dat += "<br>Selected Server: [SelectedServer.id]<br><br>"
		dat += "<br><a href='?src=\ref[src];operation=editcode'>\[Edit Code\]</a>"
		dat += "<br>Signal Execution: "
		if(SelectedServer.autoruncode)
			dat += "<a href='?src=\ref[src];operation=togglerun'>ALWAYS</a>"
		else
			dat += "<a href='?src=\ref[src];operation=togglerun'>NEVER</a>"

	if(screen == 2) //code editor
		if(editingcode == user)
			dat += {"<br>[temp]<br>
					<center>
					<a href='?src=\ref[src];operation=codeback'>\[Back\]</a>
					<a href='?src=\ref[src];operation=mainmenu'>\[Main Menu\]</a>
					<a href='?src=\ref[src];operation=refresh'>\[Refresh\]</a>
					</center>

					<style type="text/css">
						.CodeMirror {
						  height: auto;
						}
						button {
							color: #ffffff;
							text-decoration: none;
							background: #40628a;
							border: 1px solid #161616;
							padding: 1px 4px 1px 4px;
							margin: 0 2px 0 0;
							cursor:default;
						}
						button:hover {
							color: #40628a;
							background: #ffffff;
						}
					</style>

					<div class="statusDisplay">
						<textarea id="fSubmit" name="cMirror">[storedcode]</textarea>
					</div>

					<script type="text/javascript">
						var cMirror_fSubmit = CodeMirror.fromTextArea(document.getElementById("fSubmit"),
						{
							lineNumbers: true,
							indentUnit: 4,
							indentWithTabs: true,
							mode: "NTSL",
							theme: "lesser-dark",
							viewportMargin: Infinity
						}
						);

						function compileCode() {
							var codeText = cMirror_fSubmit.getValue();
							window.location = "byond://?src=\ref[src];choice=Compile;cMirror=" + encodeURIComponent(codeText);
						}

						function clearCode() {
							window.location = "byond://?src=\ref[src];choice=Clear;";
						}
					</script>
					<a href="javascript:compileCode()">Compile</a>
					<a href="javascript:clearCode()">Clear</a>

					<div class="item">
						[compiling_errors]
					</div>
					"}
		else
			dat += {"<br>[temp]<br>
					<center><a href='?src=\ref[src];operation=refresh'>\[Refresh\]</a></center>
					<div class="item" style="width:80%">
						<textarea id="fSubmit" name="cMirror">
							[storedcode]
						</textarea>
						<script>
							var editor = CodeMirror.fromTextArea(document.getElementById("fSubmit"),
							{
							lineNumbers: true,
							indentUnit: 4,
							indentWithTabs: true,
							mode: "NTSL",
							theme: "lesser-dark",
							viewportMargin: Infinity
							}
							);
						</script>
					</div>
					<div class="item">
						[compiling_errors]
					</div>
					"} //anything typed will be overridden anyways by the one who is editing the code

	var/datum/browser/popup = new(user, "traffic_control", "Telecommunication Traffic Control", 700, 500)
	//codemirror
	popup.add_script("codemirror-compressed", 'nano/js/codemirror-compressed.js') // A custom compressed JS file of codemirror, with CSS highlighting
	popup.add_stylesheet("codemirror", 'nano/css/codemirror.css') // this CSS sheet is common to all UIs, so all UIs can use codemirror
	popup.add_stylesheet("lesser-dark", 'nano/css/lesser-dark.css') //CSS styling for codemirror, dark theme

	popup.set_content(dat)
	popup.open()

	temp = ""


/obj/machinery/computer/telecomms/traffic/Topic(href, href_list)
	if(..())
		return 1

	var/mob/user = usr
	if(!istype(user) || !user.client)
		return 0

	if(user != editingcode)
		return 0

	var/code = href_list["cMirror"]
	if(code)
		storedcode = code

	add_fingerprint(user)
	user.set_machine(src)

	if(!allowed(user) && !emagged)
		user << "<span class='danger'>Access Denied.</span>"
		return 0

	switch(href_list["choice"])
		if("Compile")
			if(!code)
				return 0
			if(user != editingcode)
				return 0 //only one editor

			if(SelectedServer)
				var/obj/machinery/telecomms/server/Server = SelectedServer
				Server.setcode(code)

				spawn(0)
					// Output all the compile-time errors
					compiling_errors = "<font color = black>Please wait, compiling...</font>"
					updateUsrDialog()

					var/list/compileerrors = Server.compile(user) // then compile the code!
					if(!telecomms_check(user))
						return

					if(compileerrors.len)
						compiling_errors = "<b>Compile Errors</b><br>"
						for(var/datum/scriptError/e in compileerrors)
							compiling_errors += "<font color = red>\t>[e.message]</font></br>"
						compiling_errors += "([compileerrors.len] errors)"


					else
						compiling_errors = "<font color='#4266DB'>TCS compilation successful!</font><br>"
						compiling_errors += "(0 errors)"

					updateUsrDialog()

		if("Clear")
			if(!telecomms_check(user) || user != editingcode)
				return 0

			if(SelectedServer)
				var/obj/machinery/telecomms/server/Server = SelectedServer
				Server.memory = list() // clear the memory

				compiling_errors = "<font color='#4266DB'>Server Memory Cleared!</font>"
				storedcode = null
				updateUsrDialog()

	if(href_list["viewserver"])
		screen = 1
		for(var/obj/machinery/telecomms/T in servers)
			if(T.id == href_list["viewserver"])
				SelectedServer = T
				break

	if(href_list["operation"])
		switch(href_list["operation"])

			if("release")
				servers = list()
				screen = 0

			if("mainmenu")
				screen = 0

			if("codeback")
				if(SelectedServer)
					screen = 1

			if("scan")
				if(servers.len > 0)
					temp = "<font color = #D70B00>- FAILED: CANNOT PROBE WHEN BUFFER FULL -</font color>"

				else
					for(var/obj/machinery/telecomms/server/T in range(25, src))
						if(T.network == network)
							servers.Add(T)

					if(!servers.len)
						temp = "<font color = #D70B00>- FAILED: UNABLE TO LOCATE SERVERS IN \[[network]\] -</font color>"
					else
						temp = "<font color = #336699>- [servers.len] SERVERS PROBED & BUFFERED -</font color>"

					screen = 0

			if("editcode")
				screen = 2

			if("togglerun")
				SelectedServer.autoruncode = !(SelectedServer.autoruncode)

	if(href_list["network"])

		var/newnet = input(user, "Which network do you want to view?", "Comm Monitor", network) as null|text

		if(newnet && canAccess(user))
			if(length(newnet) > 15)
				temp = "<font color = #D70B00>- FAILED: NETWORK TAG STRING TOO LENGHTLY -</font color>"

			else

				network = newnet
				screen = 0
				servers = list()
				temp = "<font color = #336699>- NEW NETWORK TAG SET IN ADDRESS \[[network]\] -</font color>"

	updateUsrDialog()

/obj/machinery/computer/telecomms/traffic/attackby(var/obj/item/weapon/D as obj, var/mob/user as mob, params)
	if(istype(D, /obj/item/weapon/screwdriver))
		playsound(get_turf(src), 'sound/items/Screwdriver.ogg', 50, 1)
		if(do_after(user, 20, target = src))
			if (src.stat & BROKEN)
				user << "\blue The broken glass falls out."
				var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
				new /obj/item/weapon/shard(loc)
				var/obj/item/weapon/circuitboard/comm_traffic/M = new /obj/item/weapon/circuitboard/comm_traffic( A )
				for (var/obj/C in src)
					C.loc = src.loc
				A.circuit = M
				A.state = 3
				A.icon_state = "3"
				A.anchored = 1
				qdel(src)
			else
				user << "\blue You disconnect the monitor."
				var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
				var/obj/item/weapon/circuitboard/comm_traffic/M = new /obj/item/weapon/circuitboard/comm_traffic( A )
				for (var/obj/C in src)
					C.loc = src.loc
				A.circuit = M
				A.state = 4
				A.icon_state = "4"
				A.anchored = 1
				qdel(src)
	src.updateUsrDialog()
	return

/obj/machinery/computer/telecomms/traffic/emag_act(user as mob)
	if(!emagged)
		playsound(get_turf(src), 'sound/effects/sparks4.ogg', 75, 1)
		emagged = 1
		user << "\blue You you disable the security protocols"

/obj/machinery/computer/telecomms/traffic/proc/canAccess(var/mob/user)
	if(issilicon(user) || in_range(user, src))
		return 1
	return 0

/obj/machinery/computer/telecomms/traffic/proc/telecomms_check(var/mob/mob)
	//writepanic("[__FILE__].[__LINE__] (no type)([usr ? usr.ckey : ""])  \\/proc/telecomms_check() called tick#: [world.time]")
	if(mob && istype(mob.machine, /obj/machinery/computer/telecomms/traffic) && in_range(mob.machine, mob) || issilicon(mob) && istype(mob.machine, /obj/machinery/computer/telecomms/traffic))
		return 1
	return 0
