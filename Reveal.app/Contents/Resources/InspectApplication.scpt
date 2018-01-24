on run argv

	set paramBundleID to missing value
	set paramDeviceName to missing value

	do shell script "open -a Reveal --args -suppressAutoConnect YES"

	if (count of argv) = 2 then
		set paramBundleID to (item 1 of argv) as text -- ie. "com.ittybittyapps.Soundstagram"
		set paramDeviceName to (item 2 of argv) as text -- ie. "iPad Simulator"
	else
		display dialog "Please enter the application's bundle identifier you wish to inspect:" default answer "com.ittybittyapps.Soundstagram"
		set paramBundleID to text returned of result

		tell application "Reveal" to set availableServices to the device name of reveal services

		if (count of availableServices) > 0 then
			(choose from list availableServices ¬
				with prompt "Please select the device that you wish to inspect on:")
			set paramDeviceName to result as text
		else
			display dialog "Please enter the simulator or device name that you wish to inspect on:" default answer "iPhone Simulator"
			set paramDeviceName to text returned of result
		end if
	end if

	if paramBundleID is equal to missing value or paramDeviceName is equal to missing value or paramBundleID is equal to "" or paramDeviceName is equal to "" then
		-- Just bail and log an error if the user hasn't provided enough information
		log "Sorry, a valid bundle identifier and device name are required to ask Reveal to inspect an application!"
	else

		tell application "Reveal"

			set matchingDocument to missing value
			set emptyDocument to missing value
			set matchingService to missing value

			-- Scan through the app's available windows looking for:
			--	1. A window with a matching reveal service, and store it in `matchingService`
			--	2. An empty window, and store it in `emptyDocument`
			repeat with currentWindow in windows
				set revealDocument to the document of currentWindow
				set revealDocumentFile to (a reference to the file of revealDocument)
				set revealService to (a reference to the selected service of revealDocument)

				if revealDocument is not equal to missing value and loadedFromDisk of revealDocument is not true then
					if the contents of revealService is equal to missing value then
						set emptyDocument to revealDocument
					else if the contents of revealService is not equal to missing value then
						if my serviceMatches(revealService, paramBundleID, paramDeviceName) then
							set matchingDocument to revealDocument
							set matchingService to (a reference to revealService)
							exit repeat
						end if
					end if
				end if
			end repeat

			activate

			set documentToRefresh to my selectDocument(matchingDocument, emptyDocument)
			set refreshResult to my selectService(matchingService, documentToRefresh, paramBundleID, paramDeviceName)

		end tell
	end if
end run

-- Checks if the passed service matches the passed bundle identifier and device name.
on serviceMatches(revealService, bundleID, deviceName)
	if application "Reveal" is running then
		tell application "Reveal"
			set serviceBundleIdentifier to the application bundle identifier of revealService
			set serviceDeviceName to the device name of revealService
			return bundleID = serviceBundleIdentifier and deviceName = serviceDeviceName
		end tell
	end if
end serviceMatches

-- Unwraps and returns the appropriate document based on what's available. Never returns a missing value.
on selectDocument(matchingDocument, emptyDocument)
	if application "Reveal" is running then
		tell application "Reveal"
			if matchingDocument is not equal to missing value then
				return matchingDocument
			else if emptyDocument is not equal to missing value then
				return emptyDocument
			else
				make new document
				return document 1 -- Newly created documents are always at 1
			end if
		end tell
	end if
end selectDocument

-- Selects the passed reveal service by setting it as the selected service of the passed document.
--	If no service is available, a request will be made to wait for one that matches the passed bundle identifier and device name.
--	If a valid service and document are passed, they are combined and refreshed immediately.
on selectService(revealService, revealDocument, bundleID, deviceName)
	tell application "Reveal"
		if the contents of revealService is not equal to missing value then
			set selected service of revealDocument to revealService
			revealDocument refresh when now
		else
			revealDocument refresh application bundle identifier bundleID device name deviceName when available
		end if
	end tell
end selectService
