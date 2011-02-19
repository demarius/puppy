fs            = require "fs"
Client        = require("mysql").Client
exec          = require("child_process").exec
spawn         = require("child_process").spawn
Danger        = require("common/danger").Danger

class Abend
  constructor: (@syslog, @message, @dump) ->
  die: ->
    @syslog.send "err", @message, @dump, -> process.exit 1

module.exports.createDatabase = (syslog, callback) ->
  shell = new (require("common/shell").Shell)(syslog)
  shell.doas "database", "/puppy/bin/database", [], null, (stdout) ->
    {host, password} = JSON.parse(stdout)
    callback(new Database(syslog, host, password))

class Database
  constructor: (@syslog, @host, @password) ->
    @queries = {}
    for file in fs.readdirSync __dirname + "/../queries"
      @queries[file] = fs.readFileSync __dirname + "/../queries/" + file , "utf8"

  createClient: ->
    client            = new Client()
    client.host       = @host
    client.user       = "puppy"
    client.password   = @password
    client.database   = "puppy"

    client

  select: (query, parameters, get, callback) ->
    if typeof get is "function"
      callback = get
      get = null
    client = @createClient()
    client.on "error", -> process.stdout.write "ERROR: MySQL Missing."
    client.connect (error) =>
      throw error if error
      client.on "end", -> client.destroy()
      client.query @queries[query], parameters, (error, results, fields) =>
        client.end -> client.destroy()
        if error
          if @error
            @error(error, this)
            @error = null
          else
            throw error
        else
          @error = null
          if get
            expanded = []
            for result in results
              expanded.push @treeify result, get
          else
            expanded = results
          callback expanded, fields

  treeify: (record, get) ->
    tree = {}
    for key, value of record
      parts = key.split /__/
      branch = tree
      for i in [0...parts.length - 1]
        branch = branch[parts[i]] = branch[parts[i]] or {}
      branch[parts[parts.length - 1]] = record[key]
    tree[get]

  getLocalUserAccount: (localUserId, callback) ->
    exec "/bin/hostname", (error, stdout) =>
      throw error if error
      hostname = stdout.substring(0, stdout.length - 1)
      @select "getLocalUserAccount", [ hostname, localUserId ], "account", (results) ->
        callback(results.shift())

  fetchLocalPort: (machineId, localUserId, service, callback) ->
    @select "fetchLocalPort", [ localUserId, service, machineId ], (results) =>
      if results.affectedRows is 0
        @createLocalPort machineId, localUserId, service, callback
      else
        @select "getLocalPortByAssignment", [ results.insertId ], "localPort", (results) ->
          callback(results.shift())

  createLocalPort: (machineId, localUserId, service, callback) ->
    @select "nextLocalPort", [ machineId ], (results) =>
      nextLocalPort = results[0].nextLocalPort
      @error = (error) =>
        throw error if error.number isnt 1062
        @createLocalPort machineId, localUserId, service, callback
      @select "insertLocalPort", [ machineId, nextLocalPort ], (results) =>
        @fetchLocalPort machineId, localUserId, service, callback

  fetchLocalUser: (applicationId, callback) ->
    @select "getMachines", [], "machine", (results) =>
      machine = results[0]
      @error = (error) =>
        throw error if error.number isnt 1062
        @fetchLocalUser applicationId, callback
      @select "fetchLocalUser", [ applicationId, machine.id, 0 ], (results) =>
        if results.affectedRows is 0
          @createLocalUser applicationId, machine.id, callback
        else
          @select "getLocalUserByAssignment", [ results.insertId ], "localUser", (results) ->
            callback(results.shift())

  createLocalUser: (applicationId, machineId, callback) ->
    @select "nextLocalUser", [ machineId, 9999999999 ], (results) =>
      nextLocalUserId = results[0].nextLocalUserId
      @error = (error) =>
        throw error if error.number isnt 1062
        @createLocalUser applicationId, machineId, callback
      @select "insertLocalUser", [ machineId, nextLocalUserId, 0, 1 ], (results) =>
        @fetchLocalUser applicationId, callback

  enqueue: (hostname, commands, callback) ->
    if commands.length
      command = commands.shift()
      @select "insertJob", [ JSON.stringify(command), hostname ], (results) =>
        @syslog.send "info", "Enqueued command #{command[0]}.", { command }
        @enqueue(hostname, commands, callback)
    else if callback
      callback()

  properties: (callback) ->
    @select "properties", [], (results) =>
      properties = {}
      for property in results
        properties[property.name] = property.value
      callback(properties)

  virtualHost: (name, ip, port, callback) ->
    @select "deleteVirtualHost", [ name ], (results) =>
      @select "insertVirtualHost", [ name, ip, port ], (results) =>
        if results.affectedRows is 0
          throw new Error("Unable to insert virtual host #{name}.")
        callback()

  verify: (condition, message, context) ->
    unless condition
      context or= {}
      throw new Abend @syslog, message, context

  application: (applicationId, callback) ->
    @hostname (hostname) =>
      uid = process.env["SUDO_UID"]
      @verify uid > 10000, "Inexplicable uid #{uid}."
      @select "getApplicationByIdAndLocalUser", [ applicationId, hostname, uid ], "application", (applications) =>
        @verify applications.length, "No such application t#{applicationId} for u#{uid} on #{hostname}."
        callback(applications.shift())

  hostname: (callback) ->
    hostname = spawn "/bin/hostname"
    stdout = ""
    stderr = ""
    hostname.stderr.on "data", (data) -> stderr += data.toString()
    hostname.stdout.on "data", (data) -> stdout += data.toString()
    hostname.on "exit", (code) =>
      if code != 0
        @abend "Unable to execute hostname.", { code, stderr, stdout }
      callback(stdout.substring(0, stdout.length - 1))

  account: (callback) ->
    @hostname (hostname) =>
      uid = process.env["SUDO_UID"]
      @verify uid > 10000, "Inexplicable uid #{uid}."
      @select "getAccountByLocalUser", [ applicationId, hostname, uid ], "application", (application) =>
        @verify application, "No such application t#{applicationId} for u#{uid} on #{hostname}."
        callback(application)

  uncaughtException: ->
    process.on "uncaughtException", (e) =>
      if e.die
        e.die()
      else
        @syslog.send "err", "Unexpected exception.", { message: e.message, stack: e.stack }, ->
          process.exit 1
