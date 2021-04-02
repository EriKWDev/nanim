
import
  system,
  rainbow

type
  LogType* = enum
    ltInfo, ltWarning, ltError, ltLog

const
  InfoPrefix* = "[" & "Info".rfRoyalBlue1 & "]: "
  WarningPrefix* = "[" & "Warning".rfGold1 & "]: "
  ErrorPrefix* = "[" & "Error".rfDeepPink8 & "]: "
  LogPrefix* = "[" & "Log".rfLime & "]: "

proc writeToLog*(messages: varargs[string], logType: LogType = ltLog) =
  let prefix = case logType:
    of ltInfo: InfoPrefix
    of ltWarning: WarningPrefix
    of ltError: ErrorPrefix
    of ltLog: LogPrefix

  stdout.write prefix
  for message in messages:
    stdout.write message
  stdout.writeLine ""

proc log*(messages: varargs[string]) = writeToLog(messages, ltLog)
proc info*(messages: varargs[string]) = writeToLog(messages, ltInfo)
proc warn*(messages: varargs[string]) = writeToLog(messages, ltWarning)
proc error*(messages: varargs[string]) = writeToLog(messages, ltError)
