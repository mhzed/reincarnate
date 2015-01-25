
reinc = require "./"

switch reinc.afterRestart()
  when 'na'
    console.log "#{process.pid}: let me die !"
    reinc.restart()
  when 'restarted'
    console.log "#{process.pid}: re-birth !"
