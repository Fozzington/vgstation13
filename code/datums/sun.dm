/datum/sun
	var/angle
	var/dx
	var/dy
	var/rate
	var/list/solars // For debugging purposes, references solars_list at the constructor.

	// Replacement for var/counter to force the sun to move every X IC minutes.
	// To prevent excess server load the server only updates the sun's sight lines by minute(s).
	// 600 value = 1 minute.
	var/nextTime = 600

	var/lastAngle = 0

/datum/sun/New()
	solars = solars_list
	rate = rand(750, 1250) / 1000 // 75.0% - 125.0% of standard rotation.

	if (prob(50))
		rate = -rate

/*
 * Calculate the sun's position given the time of day.
 */
/datum/sun/proc/calc_position()
	var/time = world.time
	angle = ((rate * time / 100) % 360 + 360) % 360

	if (angle != lastAngle)
		var/obj/machinery/power/tracker/T

		for (T in solars_list)
			if (!T.powernet)
				solars_list.Remove(T)
				continue

			T.set_angle(angle)

	lastAngle = angle

	if (!round(time / nextTime))
		return

	nextTime *= 2

	// Now calculate and cache the (dx,dy) increments for line drawing.
	var/s = sin(angle)
	var/c = cos(angle)

	if (!c)
		dx = 0
		dy = s
	else if (abs(s) < abs(c))
		dx = s / abs(c)
		dy = c / abs(c)
	else
		dx = s / abs(s)
		dy = c / abs(s)

	var/obj/machinery/power/solars/S

	for (S in solars_list)
		if (!S.powernet)
			solar_list.Remove(S)

		if (S.control)
			occlusion(S)

/*
 * For a solar panel, trace towards sun to see if we're in shadow.
 */
/datum/sun/proc/occlusion(const/obj/machinery/power/solar/S)
	var/ax = S.x // Start at the solar panel.
	var/ay = S.y
	var/i
	var/turf/T

	for (i = 1 to 20) // 20 steps is enough.
		ax += dx // Do step.
		ay += dy

		T = locate(round(ax, 0.5), round(ay, 0.5), S.z)

		if (T.x == 1 || T.x == world.maxx || T.y == 1 || T.y == world.maxy) // Not obscured if we reach the edge.
			break

		if (T.opacity) // Opaque objects block light.
			S.obscured = 1
			return

	S.obscured = 0 // If hit the edge or stepped 20 times, not obscured.
	S.update_solar_exposure()
