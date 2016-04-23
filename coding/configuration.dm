/var/riftstation/Configuration/configuration = new

/riftstation/Configuration/var/log_level = LOG_INFO

/riftstation/Configuration/New()
	try
		var/XML/Element/root
		var/list/elements
		var/XML/Element/element
		var/temp

		root = xmlRootFromFile("config.xml")

		if (root)
			elements = root.Descendants("logger")

			if (elements.len)
				if (elements.len > 1)
					Log.PrintMessage(LOG_WARNING, "Additional 'logger' elements detected; only using the first one for processing.")

				element = elements[1]
				temp = uppertext(element.Attribute("level"))

				switch (temp)
					if ("FATAL")   log_level = LOG_FATAL
					if ("ERROR")   log_level = LOG_ERROR
					if ("WARNING") log_level = LOG_WARNING
					if ("INFO")    log_level = LOG_INFO
					if ("DEBUG")   log_level = LOG_DEBUG
					if ("TRACE")   log_level = LOG_TRACE
					else           Log.PrintMessage(LOG_WARNING, text("Unknown log level \"[]\", falling back to INFO.", temp))

			elements = root.Descendants("database")

			if (elements.len)
				if (elements.len > 1)
					Log.PrintMessage(LOG_WARNING, "Additional database connectors detected; only using the first one for processing.")

				element = elements[1]

				switch (element.Attribute("type"))
					if ("sqlite") database = new/sql4dm/SqliteDatabaseConnection(element.Attribute("file"))
					if ("mysql")  database = new/sql4dm/MysqlDatabaseConnection(element.Attribute("host"), element.Attribute("port") || 3306, element.Attribute("username"), element.Attribute("password"), element.Attribute("dbname"))
					if ("pgsql")  database = new/sql4dm/PgsqlDatabaseConnection(element.Attribute("host"), element.Attribute("port") || 3306, element.Attribute("username"), element.Attribute("password"), element.Attribute("dbname"))
					else          Log.PrintMessage(LOG_FATAL, text("Unknown database type \"[]\"", type))

				var/sql4dm/Changelog/C

				for (var/file in commons_changelogs)
					C = new(database, file)
					C.Process()

				for (var/file in project_changelogs)
					C = new(database, file)
					C.Process()
			else
				Log.PrintMessage(LOG_FATAL, "A database connection is required to run this world. Please check the \"config.xml\" file.")
		else
			Log.PrintMessage(LOG_FATAL, "File not found: \"config.xml\"")
	catch (var/exception/ex)
		Log.PrintMessage(LOG_FATAL, "Error while processing \"config.xml\" file.", ex)
