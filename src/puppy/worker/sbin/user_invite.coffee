#!/opt/bin/coffee
require.paths.unshift("/puppy/common/lib/node")

require("common/public").createShell __filename, (shell) ->
  syslog = shell.syslog

  [ email ] = process.argv.slice(2)

  sendActivation = (activation) ->
    body = """
    From: Pretty Robots <messages@prettyrobots.com>
    To: #{activation.email}
    Subject: Activate Your Account at Puppy

    Didn't expect this message? Very, very sorry. See below.
    
    Welcome to Puppy, intelligent hosting for your Node.js web
    applications, with puppy-like workflow.
    
    Activate Puppy with the following command.
    
    $ puppy account:activate #{activation.code}
    
    Didn't expect this message?
    
    Someone might be annoying you with our signup form. Using your
    email instead of their own. Please let us know that you did
    not expect this message by clicking this link.
    
    https://www.runpup.com/bogus/#{activation.code}
    
    We'll put a stop to it.
    """
    start = Date.now()
    command = shell.run "/usr/sbin/sendmail", activation.email
    command.assert "Cannot run semdmail.", body, (outcome) ->
      syslog.send "info", "Invitation sent to #{activation.email}.", { duration: Date.now() -  start }

  shell.doas "system", "/puppy/system/bin/user_activation", [ email ], null, (stdout) ->
    sendActivation(JSON.parse(stdout))