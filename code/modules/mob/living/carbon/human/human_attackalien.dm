/mob/living/carbon/human/attack_alien(mob/living/carbon/alien/humanoid/M as mob)
	if(check_shields(0, M.name))
		visible_message("\red <B>[M] attempted to touch [src]!</B>")
		return 0

	switch(M.a_intent)
		if (I_HELP)
			visible_message(text("\blue [M] caresses [src] with its scythe like arm."))
		if (I_GRAB)
			grabbedby(M)

		if(I_HARM)
			M.do_attack_animation(src)
			if (w_uniform)
				w_uniform.add_fingerprint(M)
			var/damage = rand(15, 30)
			if(!damage)
				playsound(loc, 'sound/weapons/slashmiss.ogg', 50, 1, -1)
				visible_message("\red <B>[M] has lunged at [src]!</B>")
				return 0
			var/obj/item/organ/external/affecting = get_organ(ran_zone(M.zone_sel.selecting))
			var/armor_block = run_armor_check(affecting, "melee")

			playsound(loc, 'sound/weapons/slice.ogg', 25, 1, -1)
			visible_message("\red <B>[M] has slashed at [src]!</B>")

			apply_damage(damage, BRUTE, affecting, armor_block)
			if (damage >= 25)
				visible_message("\red <B>[M] has wounded [src]!</B>")
				apply_effect(4, WEAKEN, armor_block)
			updatehealth()

		if(I_DISARM)
			M.do_attack_animation(src)
			var/randn = rand(1, 100)
			if (randn <= 80)
				var/obj/item/organ/external/affecting = get_organ(ran_zone(M.zone_sel.selecting))
				playsound(loc, 'sound/weapons/pierce.ogg', 25, 1, -1)
				apply_effect(5, WEAKEN, run_armor_check(affecting, "melee"))
				for(var/mob/O in viewers(src, null))
					if ((O.client && !( O.blinded )))
						O.show_message(text("\red <B>[] has tackled down []!</B>", M, src), 1)
			else
				if (randn <= 99)
					playsound(loc, 'sound/weapons/slash.ogg', 25, 1, -1)
					drop_item()
					visible_message(text("\red <B>[] disarmed []!</B>", M, src))
				else
					playsound(loc, 'sound/weapons/slashmiss.ogg', 50, 1, -1)
					visible_message(text("\red <B>[] has tried to disarm []!</B>", M, src))
	return