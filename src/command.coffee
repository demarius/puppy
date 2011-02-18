{Configuration} = require "./puppy"
{OptionParser}  = require "coffee-script/optparse"
fs              = require "fs"
path            = require "path"

usage = (parser, message) ->
  commands = []
  width = 0
  for file in (fs.readdirSync(__dirname).filter (file) -> /_/.test(file))
    command = file.replace /\.js$/, ""
    description = require("../lib/#{command}").command.description
    if description
      command = command.replace /_/, ":"
      width = command.length if width < command.length
      commands.push [ command, description ]
  width++ if width % 4 is 0
  width = 4 * Math.floor((width + 3) / 4)
  descriptions = []
  for command in commands
    descriptions.push "  #{command[0]}#{new Array(width - command[0].length).join(" ")}#{command[1]}"
  error = if not message then "" else """

  error: #{message}

  """
  process.stdout.write """
  #{error}
  usage: puppy [OPTIONS] [COMMAND] [OPTIONS]

  #{parser.help().replace(/^\s*Available/, 'puppy')}
  description:
    Invoke a Puppy command. Most commands accept an `--app` parameter that
    identifies the application to use by identifier or alias. Some commands are
    global and do not require an `--app` parameter, but will accept one anyway.

  available commands:
  #{descriptions.join "\n"}


  """
  process.exit if message then 1 else 0

module.exports.command = (argv) ->
  parser = new OptionParser [
    [ "-a", "--app [NAME]", "application name" ]
    [ "-l", "--list", "display listing output" ]
    [ "-j", "--json", "display json output" ]
    [ "-q", "--quiet", "display no output" ]
    [ "-h", "--help", "display puppy help" ]
  ]

  try
    options         = parser.parse process.argv.slice(2)
  catch e
    usage parser, "Invalid parameters. See usage."

  if options.help
    usage parser

  if options.arguments.length is 0
    usage parser, "Command missing. See usage."

  name = options.arguments.shift()
  if not /^\w{1,12}:\w{1,12}$/.test(name)
    usage parser, "Invalid command name. See usage."
  command = name.replace /:/, "_"

  path.exists "#{__dirname}/#{command}.js", (exists) ->
    if not exists
      usage parser, "Unknown command `#{name}`. See usage."
    configuration = new Configuration(parser, options)
    require("./#{command}").command.execute(configuration)
