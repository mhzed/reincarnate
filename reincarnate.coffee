path = require "path"
fs   = require "fs"
os   = require "os"
{spawn} = require "child_process"

module.exports = reincarnate = {

  # the idea is:
  # prepare a script that will:
  # 1. wait for this processs to die
  # 2. then call restartCmd
  # spawn script,
  # then kill self, restart does not by default kill this process, you are responsible
  restart : (restartCmd)->
    # >> update.log 2>&1
    restartCmd ?= ("\"#{a}\"" for a in process.argv).join ' '
    scriptFile = reincarnate._scriptFile()
    if os.platform() == 'win32' or os.platform() == 'win64'
      fs.writeFileSync(scriptFile, """
      @echo off
      :loop
      tasklist /FI "PID eq #{process.pid}" | find ":"
      if %ERRORLEVEL% neq 0 (
          timeout /t 1
          goto :loop
      )
      start  "" /B #{restartCmd}
      """)
      cps = spawn "cmd.exe", ["/C", "start", "/B", "/MIN", "cmd", "/c", scriptFile], {detached: true, stdio : 'ignore'}
    else
      fs.writeFileSync(scriptFile, """
      #!/bin/sh
      while kill -0 #{process.pid} > /dev/null 2>&1
      do
        sleep 0.5
      done
      #{restartCmd}
      """)
      fs.chmodSync scriptFile, '0755'
      cps = spawn scriptFile, [], {detached: true, stdio : 'inherit'}
      cps.unref()
  # detect after upgrade: call this on application startup
  # return na|restarted:  na means no restart took place,
  afterRestart : ()->
    scriptFile = reincarnate._scriptFile()
    if fs.existsSync scriptFile
      fs.unlinkSync scriptFile
      return 'restarted'
    else
      return 'na'

  _scriptFile : ()->
    if os.platform() == 'win32' or os.platform() == 'win64'
      scriptFile = path.resolve(process.cwd(), "__reincarnate.bat")
    else
      scriptFile = path.resolve(process.cwd(), "__reincarnate.sh")



}