/var/const/LOG_FATAL   = -1
/var/const/LOG_ERROR   = 0
/var/const/LOG_WARNING = 1
/var/const/LOG_INFO    = 2
/var/const/LOG_DEBUG   = 3
/var/const/LOG_TRACE   = 4

// Catch all error messages and route it through the Log proc.
/world/Error(var/ex) Log.PrintMessage(LOG_ERROR, ex)

/var/riftstation/Log/Log = new

/riftstation/Log/proc/PrintMessage(level, description, exception/exception)
	var/world_log_level

	try { world_log_level = configuration.log_level } catch { world_log_level = LOG_TRACE }

	if (level <= world_log_level)
		if (istype(description, /exception))
			exception   = description
			description = exception.name

		var/log_type

		switch (level)
			if (LOG_FATAL)   log_type = "FATAL"
			if (LOG_ERROR)   log_type = "ERROR"
			if (LOG_WARNING) log_type = "WARNING"
			if (LOG_INFO)    log_type = "INFO"
			if (LOG_DEBUG)   log_type = "DEBUG"
			if (LOG_TRACE)   log_type = "TRACE"

		var/location   = (exception ? text("[]:[]", exception.file, exception.line) : null)
		var/stacktrace = (exception ? exception.desc : null)

		try
			database.Execute("INSERT INTO log (id, level, description, location, message, created) VALUES($1, $2, $3, $4, $5, NOW())",
			                 CO.GenerateUniqueID(),
			                 log_type,
			                 description,
			                 location,
			                 stacktrace)
		catch
			// no problem

		. = text("[]: []", log_type, description)

		if (exception)
			. = text("[] (at []:[])", ., exception.file, exception.line)

		world.log << .

		// Fatal errors cause the world to shut down.
		if (level == LOG_FATAL)
			del world
